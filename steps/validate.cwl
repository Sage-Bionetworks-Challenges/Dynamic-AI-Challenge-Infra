#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: Validate predictions file
baseCommand: python3

hints:
  DockerRequirement:
    dockerPull: sagebionetworks/synapsepythonclient:v2.3.0

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - $(inputs.validate_script)

inputs:
  - id: validate_script
    type: File
  - id: evaluation_id
    type: string
  - id: input_file
    type: File?

arguments:
  - valueFrom: $(inputs.validate_script.path)
  - prefix: -e
    valueFrom: $(inputs.evaluation_id)
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
  - id: invalid_reasons
    type: string
    outputBinding:
      glob: results.json
      outputEval: $(JSON.parse(self[0].contents)['validation_errors'])
      loadContents: true