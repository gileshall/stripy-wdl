version 1.0

workflow STRipyPipeline {
    input {
        File input_bam
        String genome_build
        File reference_fasta
        String loci
        String? output_prefix
        String? docker_image = "stripy-pipeline:latest"
        Int? memory_gb = 8
        Int? cpu = 2
    }

    call RunSTRipy {
        input:
            input_bam = input_bam,
            genome_build = genome_build,
            reference_fasta = reference_fasta,
            loci = loci,
            output_prefix = output_prefix,
            docker_image = docker_image,
            memory_gb = memory_gb,
            cpu = cpu
    }

    output {
        File results_json = RunSTRipy.results_json
        File results_csv = RunSTRipy.results_csv
        File log_file = RunSTRipy.log_file
        Array[File] additional_outputs = RunSTRipy.additional_outputs
    }
}

task RunSTRipy {
    input {
        File input_bam
        String genome_build
        File reference_fasta
        String loci
        String? output_prefix
        String docker_image
        Int memory_gb
        Int cpu
    }

    String output_dir = "output"
    String data_dir = "data"
    String ref_dir = "references"
    
    String bam_name = basename(input_bam)
    String ref_name = basename(reference_fasta)
    String prefix = if defined(output_prefix) then output_prefix else sub(bam_name, "\\.bam$", "")

    command {
        # Create directories
        mkdir -p ${data_dir} ${output_dir} ${ref_dir}
        
        # Copy input files
        cp ${input_bam} ${data_dir}/${bam_name}
        cp ${reference_fasta} ${ref_dir}/${ref_name}
        
        # Run STRipy pipeline
        docker run --rm \
            -v ${data_dir}:/data \
            -v ${output_dir}:/output \
            -v ${ref_dir}:/references \
            ${docker_image} \
            --input /data/${bam_name} \
            --genome ${genome_build} \
            --reference /references/${ref_name} \
            --output /output \
            --locus ${loci} \
            --prefix ${prefix} \
            2>&1 | tee ${output_dir}/stripy.log
    }

    runtime {
        docker: docker_image
        memory: "${memory_gb}G"
        cpu: cpu
        disks: "local-disk 20 HDD"
        preemptible: 3
    }

    output {
        File results_json = "${output_dir}/${prefix}_results.json"
        File results_csv = "${output_dir}/${prefix}_results.csv"
        File log_file = "${output_dir}/stripy.log"
        Array[File] additional_outputs = glob("${output_dir}/*")
    }
}
