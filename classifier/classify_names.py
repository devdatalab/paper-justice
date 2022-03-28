import argparse
import os
import pandas as pd
from lstm_classifier import LSTMClassifier


def classify_gender(mode, model_fp="", data_fn="", output_fp=""):
    """
    mode = train, classify
    model_fp = Full path to where model is stored (specify in classify mode)
    data_fn = File name, including full path, for training data (in train mode)
              or unlabelled data (in classify mode) ("railway_names_clean_full.dta")
    output_fp = filepath where data is written out to
    """
    
    # expand the home directory symbol in any filepaths
    model_fp = os.path.expanduser(model_fp)
    data_fn = os.path.expanduser(data_fn)
    output_fp = os.path.expanduser(output_fp)

    # --------------- #
    # TRAIN THE MODEL #
    # --------------- #   
    if mode == "train":
    
        # initiate name classifier object
        model = LSTMClassifier()
        
        df = pd.read_stata(data_fn)

        # make sure to only keep names with M or F as values for gender
        df = df[df['gender'].isin(["M", "F"])]
        
        # 1) CLEAN           
        df = model.clean_string(df, stringvar="full_name")

        # 2) SPLIT
        X_train_df, y_train, X_test_df, y_test = model.train_test_split(df, "full_name_clean", "gender")

        # 3) ENCODE
        X_train, top_chars = model.encode_x(X_train_df, "full_name_clean")
        X_test, top_chars = model.encode_x(X_test_df, "full_name_clean")

        # store all data in a dictionary
        training_data = {"X_train_df": X_train_df,
                         "X_train": X_train,
                         "X_test_df": X_test_df,
                         "X_test": X_test,
                         "y_train": y_train,
                         "y_test": y_test}

        # save testing and training datasets 
        pd.to_pickle(training_data, os.path.join(output_fp, "training_data.pkl"))

        # 4) TRAIN
        model_fp = model.train_model(X_train, y_train, X_test, y_test)
        
        return model_fp

    # ----------------------- #
    # CLASSIFY SAMPLE NAMES #
    # ----------------------- #
    if mode == "classify":

        # check if the model exists
        if not os.path.exists(model_fp):
            raise FileNotFoundError(f"{model_fp} file cannot be found")
       
        # load the model
        model = LSTMClassifier(model_fp=model_fp, load=True, epochs=5)
        
        print(f"Classifying names...")

        # create dictionary to hold all of the dataframe chunks
        dfs = {}
        num = 0

        # read in the data in chunks as these are large files 
        for df_chunk in pd.read_stata(data_fn, chunksize=1000000):

            # 1) CLEAN
            df_chunk = model.clean_string(df_chunk, "name")

            # 2) ENCODE
            X_data, top_chars = model.encode_x(df_chunk, "name_clean")

            # 3) CLASSIFY
            y_pred = model.predict_classes(X_data)

            # muslim prediction stored in the first column, non-muslim in the second
            df_chunk['female'] = y_pred[:, 0]
            df_chunk['male'] = y_pred[:, 1]

            # store the dataframe chunk in the dictionary
            dfs[num] = df_chunk
            del df_chunk, X_data 

            # iterate num, which is the key to storing new dataframes in dfs
            num += 1

        # append all the dataframe chunks in the dictionary into one dataframe
        df = pd.concat(dfs.values(), ignore_index=True)

        # write the dataframe out to file
        if not output_fp:
            output_fp = "names_female_class_sample.csv"
            
        # make sure the file is written out
        try:
            df.to_csv(output_fp)
        except:
            df.to_csv("names_female_class_sample.csv")
        
        print("Classification complete.")

        del dfs
