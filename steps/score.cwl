#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: Score predictions file
baseCommand: python3

hints:
  DockerRequirement:
    dockerPull: docker.synapse.org/syn52052736/synapseclient-docker:v2.3.0

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - $(inputs.score_script)
      - entryname: .docker/config.json
        entry: |
          {"auths": {"$(inputs.docker_registry)": {"auth": "$(inputs.docker_authentication)"}}}

inputs:
  - id: score_script
    type: File
  - id: evaluation_id
    type: string
  - id: input_file
    type: File?
  - id: groundtruth_path
    type: string
  - id: docker_registry
    type: string
  - id: docker_authentication
    type: string
  - id: synapse_config
    type: File
  
arguments:
  - valueFrom: $(inputs.score_script.path)
  - prefix: -e
    valueFrom: $(inputs.evaluation_id)
  - prefix: -g
    valueFrom: $(inputs.groundtruth_path)
  - prefix: -i
    valueFrom: $(inputs.input_file)
  - prefix: -c
    valueFrom: $(inputs.synapse_config.path)
  - prefix: -o
    valueFrom: results.json

outputs:
  - id: results
    type: File
    outputBinding:
      glob: results.json