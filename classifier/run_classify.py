import os
import pandas as pd
from classify_names import classify_gender

# ------ #
# Config #
# ------ #
# for all filepaths, either specify the absolute filepath or
# the filepath relative to the home directory that this file sits in

# filepath for the model
model_fp = "classification/delhi_names_gender.hdf5"

# filepath for the data
data_fp = "classification/sample_names.csv"

# filepath for outputs
output_folder = "output"


# check that all the file paths and folders exits
if not os.path.exists(model_fp):
    raise ValueError("model filepath does not exist")
if not os.path.exists(data_fp):
    raise ValueError("data filepath does not exist")

# if the output folder doesn't exist, create it
if not os.path.exists(output_folder):
    os.mkdir(output_folder)

# -------- #
# Classify #
# -------- #

# call the main classification function
classify_gender("classify", model_fp=model_fp, data_fn=data_fp, output_fp=output_folder)

# read in the results
df = pd.read_csv(os.path.join(output_folder, "names_female_class_sample.csv"))

# rename output to clearly state that it is probability
df = df.rename(columns={"female": "prob_female"})

# drop male column
df = df.drop(["male"], axis=1)
               
# define probabilty thresholds to create categorical assignment
def thresh_prob(x):
    if x >= 0.65:
        return 1
    elif x < 0.35:
        return 0
    else:
        return -9998

# assign categorical variabel
df["female"] = df["prob_female"].apply(thresh_prob)

# replace missing value code with -9999 if the name is also missing
df.loc[(df["name_clean"].isnull()), "female"] = -9999

# print out the results, the coding is now:
# 1: female
# 0: male
# -9998: model assignment is unclear
# -9999: name is missing
Counter(df["female"])

# output final data
df.to_csv(os.path.join(output_folder, "female_name_assignment.csv"), index=False)
