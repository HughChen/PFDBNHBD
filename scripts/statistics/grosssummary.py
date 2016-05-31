"""
grosssummary.py will parse all the bxb report files, and calculate the relevant statistics
for an algorithm on a dataset. grosssummary.py assumes that it is run in the same directory
that contains the report files.

gross.csv - a csv with the sensitivity and predictivity for each record, and the average
sensitivity, average predictivity, gross sensitivity, and gross predictivity for the
entire dataset.
"""
import glob
import os
import re
import csv

SENSITIVITY = "QRS sensitivity"
PREDICTIVITY = "QRS positive predictivity"

with open('gross.csv', 'wb') as csvfile:
    fieldnames = ['record_name', 'predictivity', 'sensitivity']
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()
    # Used to calculate gross sensitivity and predictivity
    total_true_positives = 0
    total_false_negatives = 0
    total_false_positives = 0
    # Arrays storing sensitivity and predictivity for each record, used to calculate averages
    sensitivity_records = []
    predictivity_records = []
    # goes through all the bxb report files
    for file_name in glob.glob("*.txt"):
        with open(file_name) as header_file:
            file_lines = header_file.readlines()
            file_lines = file_lines[1:]
            output_dict = {'record_name': file_name}
            for line in file_lines:
                if SENSITIVITY in line: # corresponds to line telling us the sensitivity
                    parentheses_content = line[line.find("(")+1:line.find(")")]
                    splitted = parentheses_content.split("/")
                    true_positives = int(splitted[0])
                    true_positives_plus_false_negatives = int(splitted[1])
                    false_negatives = true_positives_plus_false_negatives - true_positives

                    total_true_positives = total_true_positives + true_positives
                    total_false_negatives = total_false_negatives + false_negatives

                    if true_positives_plus_false_negatives == 0:
                        percentage = "-"
                        sensitivity_records.append(0)
                        print str(file_name) + " has 0/0 for sensitivity"
                    else:
                        percentage = float(true_positives) / true_positives_plus_false_negatives
                        sensitivity_records.append(percentage)
                    output_dict['sensitivity'] = percentage
                elif PREDICTIVITY in line: # corresponds to the line telling us the predictivity
                    parentheses_content = line[line.find("(")+1:line.find(")")]
                    splitted = parentheses_content.split("/")
                    true_positives = int(splitted[0])
                    true_positives_plus_false_positives = int(splitted[1])
                    false_positives = true_positives_plus_false_positives - true_positives

                    # DONT ADD THE TRUE POSITIVES TWICE
                    total_false_positives = total_false_positives + false_positives

                    if true_positives_plus_false_positives == 0:
                        percentage = "-"
                        total_false_positives = total_false_positives + 1
                        predictivity_records.append(0)
                        print str(file_name) + " has 0/0 for predictivity"
                    else:
                        percentage = float(true_positives) / true_positives_plus_false_positives
                        predictivity_records.append(percentage)
                    output_dict['predictivity'] = percentage
            # writes out the line to the output .csv
            writer.writerow(output_dict)

    # Writes out gross and average statistics at the end of the CSV.
    gross_predictivity = float(total_true_positives) / (total_true_positives + total_false_positives)
    gross_predictivity_row = {'record_name': 'Gross', 'predictivity': 'Predictivity', 'sensitivity': gross_predictivity}
    writer.writerow(gross_predictivity_row)

    gross_sensitivity = float(total_true_positives) / (total_true_positives + total_false_negatives)
    gross_sensitivity_row = {'record_name': 'Gross', 'predictivity': 'Sensitivity', 'sensitivity': gross_sensitivity}
    writer.writerow(gross_sensitivity_row)

    average_predictivity_row = { 'record_name': 'Average', 'predictivity': 'Predictivity', 
        'sensitivity': sum(predictivity_records) / float(len(predictivity_records)) }
    writer.writerow(average_predictivity_row)

    average_sensitivity_row = { 'record_name': 'Average', 'predictivity': 'Sensitivity', 
        'sensitivity': sum(sensitivity_records) / float(len(sensitivity_records)) }
    writer.writerow(average_sensitivity_row)
