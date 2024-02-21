#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: Score predictions file
baseCommand: python3

hints:
  DockerRequirement:
    dockerPull: sagebionetworks/synapsepythonclient:v2.3.0

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - $(inputs.score_script)

inputs:
  - id: score_script
    type: File
  - id: evaluation_id
    type: string
  - id: input_file
    type: File?
  - id: groundtruth_path
    type: File
  
arguments:
  - valueFrom: $(inputs.score_script.path)
  - prefix: -e
    valueFrom: $(inputs.evaluation_id)
  - prefix: -g
    valueFrom: $(inputs.groundtruth_path)
  - prefix: -i
    valueFrom: $(inputs.input_file)
  - prefix: -o
    valueFrom: results.json

outputs:
  - id: results
    type: File
    outputBinding:
      glob: results.json
  - id: status
    type: string
    outputBinding:
      glob: results.json
      outputEval: $(JSON.parse(self[0].contents)['validation_status'])
      loadContents: true