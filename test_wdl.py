#!/usr/bin/env python3

import os
import sys
import subprocess
import json
import shutil
from pathlib import Path
import urllib.request
import gzip

class STRipyTester:
    def __init__(self):
        self.base_dir = Path.cwd()
        self.test_dir = self.base_dir / "test-env"
        self.test_outputs_dir = self.test_dir / "test-outputs"
        self.docker_image = "stripy-pipeline:latest"
        
    def run_command(self, cmd, check=True):
        """Run a command and return result"""
        print(f"Running: {cmd}")
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if check and result.returncode != 0:
            print(f"Command failed: {cmd}")
            print(f"STDOUT: {result.stdout}")
            print(f"STDERR: {result.stderr}")
            sys.exit(1)
        return result
    
    def check_miniwdl(self):
        """Check if miniwdl is installed"""
        if not shutil.which("miniwdl"):
            print("❌ miniwdl not found. Please install it first:")
            print("   pip install miniwdl")
            sys.exit(1)
        print("✅ miniwdl found")
    
    def check_docker_image(self):
        """Check if Docker image exists, build if not"""
        result = subprocess.run(f"docker image inspect {self.docker_image}", 
                              shell=True, capture_output=True)
        if result.returncode != 0:
            print(f"⚠️  Docker image '{self.docker_image}' not found.")
            print("   Building it now...")
            self.run_command(f"./build.sh --tag {self.docker_image}")
        else:
            print(f"✅ Docker image '{self.docker_image}' found")
    
    def download_file(self, url, dest_path, description):
        """Download a file if it doesn't exist"""
        if dest_path.exists():
            print(f"✅ {description} already exists")
            return
        
        print(f"📥 Downloading {description}...")
        dest_path.parent.mkdir(parents=True, exist_ok=True)
        
        try:
            urllib.request.urlretrieve(url, dest_path)
            print(f"✅ {description} downloaded")
        except Exception as e:
            print(f"❌ Failed to download {description} from {url} : {e}")
            sys.exit(1)
    
    def setup_test_environment(self):
        """Create test directory and download all necessary test files"""
        print("\n🔧 Setting up test environment...")
        
        # Create test directory structure
        self.test_dir.mkdir(exist_ok=True)
        (self.test_dir / "NA12878").mkdir(exist_ok=True)
        (self.test_dir / "references").mkdir(exist_ok=True)
        (self.test_dir / "test-outputs").mkdir(exist_ok=True)
        
        print(f"📁 Created test directory: {self.test_dir}")
        
        # Download CRAM file
        cram_url = "https://42basepairs.com/download/s3/1000genomes/1000G_2504_high_coverage/data/ERR3239334/NA12878.final.cram"
        cram_path = self.test_dir / "NA12878" / "NA12878.final.cram"
        self.download_file(cram_url, cram_path, "NA12878 CRAM file")
        
        # Download CRAM index
        crai_url = "https://42basepairs.com/download/s3/1000genomes/1000G_2504_high_coverage/data/ERR3239334/NA12878.final.cram.crai"
        crai_path = self.test_dir / "NA12878" / "NA12878.final.cram.crai"
        self.download_file(crai_url, crai_path, "NA12878 CRAM index")
        
        # Download hg38 reference (keep compressed)
        hg38_url = "https://hgdownload.soe.ucsc.edu/goldenpath/hg38/bigZips/hg38.fa.gz"
        hg38_gz_path = self.test_dir / "references" / "hg38.fa.gz"
        self.download_file(hg38_url, hg38_gz_path, "hg38 reference (compressed)")
        
        # Download hg38 index
        hg38_idx_url = "https://hgdownload.soe.ucsc.edu/goldenpath/hg38/bigZips/hg38.fa.fai"
        hg38_idx_path = self.test_dir / "references" / "hg38.fa.fai"
        self.download_file(hg38_idx_url, hg38_idx_path, "hg38 reference index")
        
        print("✅ Test environment setup complete")
    
    def validate_wdl(self):
        """Validate WDL syntax"""
        print("\n🔍 Validating WDL syntax...")
        result = self.run_command("miniwdl check stripy-pipeline.wdl", check=False)
        if result.returncode != 0:
            print("❌ WDL validation failed!")
            sys.exit(1)
        print("✅ WDL validation passed")
    
    def create_test_inputs(self, test_name, loci_value):
        """Create test inputs JSON for a specific test"""
        test_inputs = {
            "STRipyPipeline.input_bam": "NA12878/NA12878.final.cram",
            "STRipyPipeline.input_bam_index": "NA12878/NA12878.final.cram.crai",
            "STRipyPipeline.genome_build": "hg38",
            "STRipyPipeline.reference_fasta": "references/hg38.fa.gz",
            "STRipyPipeline.locus": loci_value,
            "STRipyPipeline.sex": "female",
            "STRipyPipeline.analysis": "standard",
            "STRipyPipeline.docker_image": self.docker_image,
            "STRipyPipeline.memory_gb": 16,
            "STRipyPipeline.cpu": 4
        }
        
        test_file = self.test_dir / f"test-inputs-{test_name}.json"
        with open(test_file, 'w') as f:
            json.dump(test_inputs, f, indent=2)
        
        return test_file
    
    def run_test(self, test_name, loci_value):
        """Run a single test case"""
        print(f"\n🧪 Running test: {test_name}")
        print(f"Loci: {loci_value}")
        
        # Create test inputs
        test_inputs_file = self.create_test_inputs(test_name, loci_value)
        print(f"Created test inputs: {test_inputs_file}")
        
        # Create test outputs directory
        test_output_dir = self.test_outputs_dir / f"test-{test_name}"
        test_output_dir.mkdir(parents=True, exist_ok=True)
        
        # Change to test directory for running the workflow
        original_cwd = os.getcwd()
        os.chdir(self.test_dir)
        
        try:
            # Run the workflow
            print("🚀 Starting WDL workflow...")
            cmd = f"miniwdl run {self.base_dir}/stripy-pipeline.wdl -i {test_inputs_file.name} -d {test_output_dir.name} -v"
            result = self.run_command(cmd, check=False)
            
            if result.returncode == 0:
                print(f"✅ Test '{test_name}' completed successfully!")
                
                # Count test runs
                run_count = len(list(self.test_outputs_dir.glob("*STRipyPipeline*")))
                print(f"📊 Total test runs: {run_count}")
                
                return True
            else:
                print(f"❌ Test '{test_name}' failed!")
                return False
        finally:
            # Always return to original directory
            os.chdir(original_cwd)
    
    def cleanup_test_files(self):
        """Clean up temporary test input files"""
        for test_file in self.test_dir.glob("test-inputs-*.json"):
            test_file.unlink()
            print(f"🧹 Cleaned up: {test_file}")
    
    def show_test_environment_info(self):
        """Show information about the test environment"""
        print(f"\n📁 Test Environment: {self.test_dir}")
        print("=" * 50)
        print(f"NA12878 CRAM: {self.test_dir / 'NA12878' / 'NA12878.final.cram'}")
        print(f"NA12878 Index: {self.test_dir / 'NA12878' / 'NA12878.final.cram.crai'}")
        print(f"hg38 Reference: {self.test_dir / 'references' / 'hg38.fa.gz'}")
        print(f"hg38 Index: {self.test_dir / 'references' / 'hg38.fa.fai'}")
        print(f"Test Outputs: {self.test_outputs_dir}")
    
    def run_all_tests(self):
        """Run all test cases"""
        print("🧪 STRipy WDL Test Suite")
        print("=" * 50)
        
        # Setup
        self.check_miniwdl()
        self.check_docker_image()
        self.setup_test_environment()
        self.validate_wdl()
        
        # Show test environment info
        self.show_test_environment_info()
        
        # Test cases
        test_cases = [
            ("individual-loci", "HTT,ATXN3,AFF2"),
            ("all-loci-profile", "all_loci")
        ]
        
        results = []
        for test_name, loci_value in test_cases:
            success = self.run_test(test_name, loci_value)
            results.append((test_name, success))
        
        # Summary
        print("\n📊 Test Results Summary")
        print("=" * 50)
        for test_name, success in results:
            status = "✅ PASS" if success else "❌ FAIL"
            print(f"{test_name}: {status}")
        
        # Cleanup
        self.cleanup_test_files()
        
        # Exit with appropriate code
        all_passed = all(success for _, success in results)
        if all_passed:
            print("\n🎉 All tests passed!")
            print(f"📁 Test results available in: {self.test_outputs_dir}")
            sys.exit(0)
        else:
            print("\n💥 Some tests failed!")
            print(f"📁 Check test outputs in: {self.test_outputs_dir}")
            sys.exit(1)

def main():
    tester = STRipyTester()
    tester.run_all_tests()

if __name__ == "__main__":
    main()
raise
            