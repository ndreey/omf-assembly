## Draft Genome Assembly of Three Orchid Mycorrhizal Fungi

### Background
We cultured three fungal isolates from orchid roots (_Platanthera_ spp.) and sequenced them using Illumina 150 bp paired-end whole genome shotgun sequencing. We believe these to be one _Tulasnella_ sp. (tula1) and two _Ceratobasidium_ spp. (cerat1, cerat2).

We assembled each isolate using two pipelines: AAFTF and FunFlux. The pipelines differ in three ways. AAFTF includes merged singleton reads in the assembly; FunFlux uses only paired-end reads. AAFTF polishes assemblies with Pilon; FunFlux does not. AAFTF applies a 1000 bp contig length filter; FunFlux applies 2000 bp. We stopped FunFlux at the length-filtered stage (`contigs_filt.fasta`) because subsequent taxonomic filtering removed too many contigs.

### Sequencing Quality
Library quality varied across isolates.

|Sample|Adapter (%)|Reads Passing Filter (%)|Duplication (%)|
|---|---|---|---|
|cerat1|6.7|95.1|0.50|
|tula1|15.5|95.4|0.47|
|cerat2|57.4|86.7|0.78|

Cerat2 had severe adapter contamination. Over half the raw reads contained adapter sequences. This reduced the usable data for assembly.

### K-mer Analysis
GenomeScope2 and Smudgeplot analysis revealed potential ploidy differences among isolates.

Tula1 and cerat1 appear diploid. Both show dominant AB signals (74% and 72%) in smudgeplots. GenomeScope estimates genome sizes of 64.5 Mb and 60.4 Mb with approximately 70% unique sequence content.

Cerat2 indicates triploidy. The smudgeplot shows a dominant AAB signal (45%) rather than AB. A diploid model estimated 100 Mb with only 32% unique sequence. A triploid model estimated 66.6 Mb with 58% unique sequence. 

### Assembly Statistics

|Metric|cerat1 AAFTF|cerat1 FunFlux|cerat2 AAFTF|cerat2 FunFlux|tula1 AAFTF|tula1 FunFlux|
|---|---|---|---|---|---|---|
|Size (Mb)|68.7|53.6|94.2|60.3|63.0|53.6|
|Contigs|13,019|9,242|20,466|13,737|14,753|8,872|
|N50 (Kb)|8.8|7.4|7.2|4.8|7.2|7.8|
|BUSCO Complete (%)|64.5|44.3|72.1|31.1|54.5|49.7|
|BUSCO Duplicated (%)|8.1|2.9|38.7|10.9|4.8|3.0|
|BUSCO Missing (%)|17.2|39.5|11.1|52.9|21.8|34.9|

### Observations Requiring Input

**Assembly completeness.** AAFTF assemblies are larger and more complete than FunFlux assemblies for all isolates. Neither pipeline approaches reference genome completeness (89%).

**FunFlux assemblies.** These have fewer contigs but higher missing BUSCO percentages. The stricter length filtering or lack of singleton reads may cause this.

### Comparative Analysis
We aim to annotate these genomes using Funannotate and compare them against JGI reference genomes. Our biological interest is nutrient acquisition in orchid mycorrhizal fungi.

However, the dotplot alignments raise questions about appropriate comparisons. Tula1 aligns somewhat to TulCal1 but the cerat assemblies shows almost no alignment to CerAGI.


### Questions
**Assembly workflow.** We are getting various levels of BUSCO completion, any best practices for shotgun assemblies? What trimming or decontamination steps do you use before assembly?  

**Annotation.** Do you have particular settings or approaches for Funannotate?

**Comparative analysis with incomplete genomes.** Which comparative approaches remain valid even with low BUSCO scores? 

**Pathway analysis.** For KEGG pathway mapping of nutrient uptake genes, does pathway completeness assessment require near-complete genomes, or can partial annotations still reveal functional differences?