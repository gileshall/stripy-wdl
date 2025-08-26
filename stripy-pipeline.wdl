version 1.0

workflow STRipyPipeline {
    input {
        File input_bam
        File input_bam_index
        String genome_build = "hg38"
        File reference_fasta
        String? locus
        String? sex
        File? custom_catalog
        String analysis = "standard"
        String? logflags
        File? config
        String docker_image = "stripy-pipeline:latest"
        Int memory_gb = 8
        Int cpu = 2
    }

    call RunSTRipy {
        input:
            input_bam = input_bam,
            input_bam_index = input_bam_index,
            genome_build = genome_build,
            reference_fasta = reference_fasta,
            locus = locus,
            sex = sex,
            custom_catalog = custom_catalog,
            analysis = analysis,
            logflags = logflags,
            config = config,
            docker_image = docker_image,
            memory_gb = memory_gb,
            cpu = cpu
    }

    output {
        Array[File] output_files = RunSTRipy.output_files
        File html_report = RunSTRipy.html_report
        File tsv_results = RunSTRipy.tsv_results
    }
}

task RunSTRipy {
    input {
        File input_bam
        File input_bam_index
        String genome_build
        File reference_fasta
        String? locus
        String? sex
        File? custom_catalog
        String analysis
        String? logflags
        File? config
        String docker_image
        Int memory_gb
        Int cpu
    }

    String output_dir = "output"

    command {
        # Run STRipy pipeline using our wrapper
        mkdir -p ${output_dir}

        stripy \
            --input ${input_bam} \
            --genome ${genome_build} \
            --reference ${reference_fasta} \
            --output ${output_dir} \
            --analysis ${analysis} \
            ${if defined(locus) then "--locus " + locus else ""} \
            ${if defined(sex) then "--sex " + sex else ""} \
            ${if defined(custom_catalog) then "--custom " + custom_catalog else ""} \
            ${if defined(logflags) then "--logflags " + logflags else ""} \
            ${if defined(config) then "--config " + config else ""}
    }

    runtime {
        docker: docker_image
        memory: "${memory_gb}G"
        cpu: cpu
        maxRetries: 2
    }

    output {
        Array[File] output_files = glob("${output_dir}/*")
        File html_report = glob("${output_dir}/*.html")[0]
        File tsv_results = glob("${output_dir}/*.tsv")[0]
    }
}
