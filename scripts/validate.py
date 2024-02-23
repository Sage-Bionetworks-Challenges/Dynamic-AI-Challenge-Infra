import argparse
import tarfile
from typing import List
from synapseclient import Synapse
import json
import os


def get_args():
    """Set up command-line interface and get arguments without any flags."""
    parser = argparse.ArgumentParser()
    parser.add_argument('-e', '--evaluation_id', type=str,
                        help='The queue ID of submission')
    parser.add_argument('-i', '--input_file', type=str,
                        help='The path to the predictions file')
    parser.add_argument('-o', '--output', type=str, nargs='?',
                        default='results.json', help='The path to output file')

    return parser.parse_args()


def get_expected_filenames(eval_id: str) -> List[str]:
    '''Generates a list of expected filename patterns based on the evaluation ID.'''
    expected_systems = ['doublependulum',
                        'Lorenz', 'Rossler', 'Lorenz96', 'KS', 'Kolmogorov']
    task_mapping = {
        '9615379': ['X1'],  # Task1
        '9615532': ['X2', 'X3', 'X4', 'X5'],  # Task2
        '9615534': ['X6'],  # Task3
        '9615535': ['X7', 'X8', 'X9']  # Task4
    }
    expected_patterns = []
    for file_prefix in task_mapping[eval_id]:
        for system in expected_systems:
            expected_patterns.append(f'{system}_{file_prefix}prediction.npy')
    return expected_patterns


def untar(directory: str, tar_filename: str, pattern='*') -> None:
    """Untar a tar file into a directory

    Args:
        directory: Path to directory to untar files
        tar_filename:  tar file path
    """
    with tarfile.open(tar_filename, 'r') as tar:
        for member in tar.getmembers():
            if member.isfile() and member.name.endswith(pattern):
                member.name = os.path.basename(member.name)
                tar.extract(member, path=directory)


def get_eval_id(syn: Synapse, submission_id: str) -> str:
    '''Get evaluation id for the submission

    Args:
        syn: Synapse connection
        submission_id (str): the id of submission

    Returns:
        sub_id (str): the evaluation ID, or None if an error occurs.
    '''
    try:
        eval_id = syn.getSubmission(submission_id).get('evaluationId')
        return eval_id
    except Exception as e:
        print(
            f'An error occurred while retrieving the evaluation ID for submission {submission_id}: {e}')
        return None


if __name__ == '__main__':

    args = get_args()
    eval_id = args.evaluation_id

    predictions_path = args.input_file
    results_path = args.output

    invalid_reasons = []

    if predictions_path is None or os.path.basename(predictions_path) != 'predictions.tar':
        prediction_status = 'INVALID'
        invalid_reasons.append('Error:  No "predictions.tar" found')
    else:
        expected_files = get_expected_filenames(eval_id)
        untar('val_predictions', tar_filename=predictions_path, pattern='.npy')
        pred_files = os.listdir('val_predictions')

        matched_files = [f for f in pred_files if f in expected_files]

        if not matched_files:
            prediction_status = 'INVALID'
            invalid_reasons.append(
                f'Error: No expected prediction file(s) found.')
        else:
            prediction_status = 'VALIDATED'

    result = {
        'validation_status': prediction_status,
        'validation_errors': ';'.join(invalid_reasons),
    }

    with open(results_path, 'w') as o:
        o.write(json.dumps(result))
    print(prediction_status)
