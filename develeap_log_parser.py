import os
import re
import time
from datetime import datetime


def get_first_line(log_file):
    with open(log_file, 'r') as file:
        first_line = file.readline()
    return first_line

def get_first_line_msg(log_file):

    first_line = get_first_line(log_file)
    print("First line in the log file:")
    print(first_line)


def count_error_lines(log_file):

    error_regex = r'ERROR'

    with open(log_file, 'r') as file:
        log_content = file.read()
    error_count = len(re.findall(f'{error_regex}', log_content))
    return error_count

def count_errors_msg(log_file):
    error_count = count_error_lines(log_file)

    print(f"Number of lines with log level ERROR: {error_count}")


def count_complete_transactions(log_file):

    # use dynamic regex expressions according to the log format
    action_start_regex = r'begun'
    action_end_regex = r'done'
    trans_regex = r'transaction'

    transaction_count = 0
    transaction_starts = set()
    transaction_ends = set()

    with open(log_file, 'r') as file:
        for line in file:
            start_match = re.search(f'{trans_regex} (\d+) {action_start_regex}', line)
            end_match = re.search(f'{trans_regex} {action_end_regex}.*id=(\d+)', line)
            if start_match:
                transaction_starts.add(start_match.group(1))
            elif end_match:
                transaction_ends.add(end_match.group(1))

    transaction_count = len(transaction_starts.intersection(transaction_ends))
    return transaction_count

def count_complete_transactions_msg(log_file):

    transaction_count = count_complete_transactions(log_file)
    print(f"Number of transactions: {transaction_count}")


def get_fastest_transaction(log_file):
    transactions = {}
    fastest_time = float('inf')
    fastest_transaction_id = None

    # use dynamic regex expressions according to the log format
    timestamp_regex = r'\d{2}-\d{1,2}-\d{4} \d{2}:\d{2}:\d{2}\.\d{3}'
    action_regex = r'begun|done'
    trans_regex = r'.*transaction'


    # transactions can occur concurrently, may occur asynchronously

    with open(log_file, 'r') as file:
        for line in file:
            start_match = re.search(f'({timestamp_regex}){trans_regex} (\d+) ({action_regex})', line)
            end_match = re.search(f'({timestamp_regex}){trans_regex} ({action_regex}).*id=(\d+)', line)

            if start_match or end_match:
                if start_match:
                    timestamp = start_match.group(1)
                    transaction_id = int(start_match.group(2))
                    action = start_match.group(3)
                else:
                    timestamp = end_match.group(1)
                    action = end_match.group(2)
                    transaction_id = int(end_match.group(3))

                if transaction_id not in transactions:
                    transactions[transaction_id] = {'start_time': None, 'end_time': None}

                if action == 'begun':
                    transactions[transaction_id]['start_time'] = timestamp
                else:
                    transactions[transaction_id]['end_time'] = timestamp

    for transaction_id, times in transactions.items():
        duration = get_duration(times['start_time'], times['end_time'])
        if duration < fastest_time:
            fastest_time = duration
            fastest_transaction_id = transaction_id

    return fastest_transaction_id

def get_duration(start_time, end_time):
    start = datetime.strptime(start_time, "%d-%m-%Y %H:%M:%S.%f")
    end = datetime.strptime(end_time, "%d-%m-%Y %H:%M:%S.%f")
    duration = (end - start).total_seconds() * 1000
    return duration

def get_fastest_transaction_msg(log_file):
    fastest_transaction_id = get_fastest_transaction(log_file)
    print("Fastest Transaction ID:", fastest_transaction_id)

'''

'''
def get_fastest_transaction_find_all_regex(log_file):
    transactions = {}
    fastest_transaction_id = 0

    # use dynamic regex expressions according to the log format
    timestamp_regex = r'\d{2}-\d{1,2}-\d{4} \d{2}:\d{2}:\d{2}\.\d{3}'
    action_regex = r'begun|done'
    trans_regex = r'.*transaction'

    with open(log_file, 'r') as file:
        log_content = file.read()

    start_list = re.findall(f'({timestamp_regex}){trans_regex} (\d+) begun', log_content)
    end_list = re.findall(f'({timestamp_regex}){trans_regex} done.*id=(\d+)', log_content)

    for trans_start in start_list:
        timestamp = trans_start[0]
        transaction_id = trans_start[1]
        transactions[transaction_id] = {'start_time': None, 'end_time': None}
        transactions[transaction_id]['start_time'] = timestamp

    for trans_end in end_list:
        timestamp = trans_end[0]
        transaction_id = trans_end[1]
        transactions[transaction_id]['end_time'] = timestamp

    fastest_transaction_id = get_fastest_duration(transactions)

    return fastest_transaction_id

# returns the minimum transaction duration time in milliseconds
def get_fastest_duration(kwargs):

    min_duration = float('inf')
    fastest_transaction_id = 0
    transactions = kwargs

    for transaction_id, times in transactions.items():
        duration = get_duration(times['start_time'], times['end_time'])

        if duration < min_duration:
            min_duration = duration
            fastest_transaction_id = transaction_id

        # average_duration = round(average_duration, 3)
    return fastest_transaction_id

def get_fastest_transaction_find_all_regex_msg(log_file):

    fastest_transaction_id = get_fastest_transaction_find_all_regex(log_file)
    print("Fastest Transaction ID:", fastest_transaction_id)

def get_avg_transaction_time(log_file):
    transactions = {}
    transactions_total_duration = 0
    transactions_num = 0
    average_duration = 0

    # use dynamic regex expressions according to the log format
    timestamp_regex = r'\d{2}-\d{1,2}-\d{4} \d{2}:\d{2}:\d{2}\.\d{3}'
    action_regex = r'begun|done'
    trans_regex = r'.*transaction'

    with open(log_file, 'r') as file:
        for line in file:
            start_match = re.search(f'({timestamp_regex}){trans_regex} (\d+) ({action_regex})', line)
            end_match = re.search(f'({timestamp_regex}){trans_regex} ({action_regex}).*id=(\d+)', line)

            if start_match or end_match:
                if start_match:
                    timestamp = start_match.group(1)
                    transaction_id = int(start_match.group(2))
                    action = start_match.group(3)
                else:
                    timestamp = end_match.group(1)
                    action = end_match.group(2)
                    transaction_id = int(end_match.group(3))

                if transaction_id not in transactions:
                    transactions[transaction_id] = {'start_time': None, 'end_time': None}

                if action == 'begun':
                    transactions[transaction_id]['start_time'] = timestamp
                else:
                    transactions[transaction_id]['end_time'] = timestamp

    for transaction_id, times in transactions.items():
        duration = get_duration(times['start_time'], times['end_time'])
        transactions_total_duration += duration
        transactions_num += 1

    if transactions_num > 0:
        average_duration = transactions_total_duration / transactions_num
        average_duration = round(average_duration, 3)

    return average_duration

def get_avg_transaction_time_msg(log_file):

    avg_transaction_time = get_avg_transaction_time(log_file)
    print("Average Transaction Time: ",avg_transaction_time)




def main():
    log_file_name= 'exam_file_log.log'

    log_file_path = os.path.join('.',log_file_name)

    # get_first_line_msg(log_file_path)

    # count_errors_msg(log_file_path)

    # count_complete_transactions_msg(log_file_path)

    start_time = time.time()
    get_fastest_transaction_msg(log_file_path)
    end_time = time.time()
    exec_time = end_time - start_time
    print(f"Execution Time is: {exec_time}")

    # get_fastest_transaction_find_all_regex(log_file_path)

    start_time = time.time()
    get_fastest_transaction_find_all_regex_msg(log_file_path)
    end_time = time.time()
    exec_time = end_time - start_time
    print(f"Execution Time using regex findall is: {exec_time}")

    # get_avg_transaction_time_msg(log_file_path)

if __name__ == '__main__':
    main()