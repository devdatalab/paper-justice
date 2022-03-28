import os
import numpy as np
import pandas as pd
from random import randint
from collections import Counter
    
from keras.models import load_model, save_model, Sequential
from keras.layers.core import Dropout, Dense
from keras.layers import Embedding, Bidirectional, LSTM
from keras.callbacks import ModelCheckpoint, EarlyStopping
from keras.preprocessing import sequence
from sklearn.utils import class_weight
from sklearn.metrics import roc_auc_score, f1_score, confusion_matrix
from sklearn.preprocessing import OneHotEncoder


class LSTMClassifier(object):

    def __init__(self, top_chars=29, embedding_vector_length=50, maxlen=40, epochs=5, batch_size=64, model_fp="", load=False):
        """
        Initiate a model either by defining a new model or loading an existing one.
        
        top_chars = the number of unique characters allowed
        embedding_vector_length = the length of the initial embedding layer, must be longer than maxlen
        maxlen = the maximum character length allowed for strings
        epochs = the number of epohcs to train the model
        batch_size = the number of observations passed for training in each batch
        model_fp = filepath to save the model
        load_model = if True, load a pre-trained model; default is False (training mode)
        """
        # if a model name is specified, load the weights from that model
        # no other parameters should be manually specified.
        if load == True:
            self.model_fp = model_fp  
            
            # check to make sure the model specified exists
            if os.path.exists(self.model_fp):              
                # extract the model from the compressed file
                self.model = load_model(self.model_fp)
                
                # get other attributes
                model_layer = self.model.get_config()["layers"][0]["config"]
                self.top_chars = model_layer["input_dim"]
                self.embedding_vector_length = model_layer["output_dim"]
                self.maxlen = model_layer["batch_input_shape"][1]

            # if it does not exist, raise an error
            else:
                raise FileNotFoundError(f"{self.model_fp} file cannot be found")
        
        # if a model name is not specified, create the model
        elif load == False:
            self.model_fp = model_fp  
            self.top_chars = top_chars
            self.embedding_vector_length = embedding_vector_length
            self.maxlen = maxlen
            self.epochs = epochs
            self.batch_size = batch_size
            
            # create the model
            self.model = self.create_model(self.top_chars, self.embedding_vector_length, self.maxlen)

            
        # generate model_fp if it is an empty string
        if model_fp == "":
            self.model_fp = f"M_lstm_100_d_50_weight.hdf5"
            

    def create_model(self, top_chars, embedding_vector_length, maxlen):
        """
        Define the layers of the LSTM model.
        """
        model = Sequential()
        model.add(Embedding(top_chars, embedding_vector_length, input_length=maxlen))
        model.add(Bidirectional(LSTM(100)))
        model.add(Dropout(0.2))
        model.add(Dense(50, activation='relu'))
        model.add(Dropout(0.2))
        model.add(Dense(2, activation='sigmoid'))
        
        return model

    
    def clean_string(self, data, stringvar, spaces=True, keepvar=False, dups=True):
        """
        Perform basic data cleaning of string data before it is passed to classifier.
        """
        # if spaces not allowed, drop them by concatenating string names
        if spaces == False:
            data["__string"] = data[stringvar].str.replace(" ", "")
            data["__string"] = data["__string"].str.lower()

        # else, copy over name column without dropping spaces
        elif spaces == True:
            data["__string"] = data[stringvar].str.lower()

        # count the character length of the names
        data["__length"] = data["__string"].apply(lambda x: len(x))

        # drop any names that are longer than 40 characters (the max length in the training set)
        data = data.drop(data.loc[data["__length"] >= self.maxlen].index)

        # drop the character count column
        data = data.drop(["__length"], axis=1)
        
        # rename the now cleaned string variable
        try:
            data = data.rename(columns={"__string": f"{stringvar}_clean"})
            new_var = f"{stringvar}_clean"
        except:
            new_var = "__string"

        data = data.drop(stringvar, axis=1)

        # drop duplicates if specified
        if not dups:
            data = data.drop_duplicates().reset_index(drop=True)
        
        # print the name of the clena string variable
        print(f"Cleaned string variables stored as: {new_var}")

        return data


    def train_test_split(self, df, stringvar, classvar, frac=0.25):
        """
        Split into a testing and training set. Make sure that all duplicated string variables
        are assigned either to the test or training set, not both.
        
        df = dataframe with trainin data 
        stringvar = variable name of the independent variable to be classified
        classvar = variables name of the target classification variable
        frac = the fraction of the dataset to be included in the test set
        """
        # get list of unique strings
        unique_strings = pd.DataFrame(list(set(df[stringvar])))

        # sample from single dataset
        random_n = randint(1, 100)
        test_strings = unique_strings.sample(frac=frac, random_state=random_n)
        test_strings = list(test_strings[0])

        # split out the training and testing dataframes based on the string assignment
        test_df = df.loc[df[stringvar].isin(test_strings)].copy() 
        train_df = df.loc[~df[stringvar].isin(test_strings)].copy() 
    
        # now create corresponding y (classification) values as onehot encoded arrays
        y_test = self.one_hot_encoding(test_df[classvar])
        y_train = self.one_hot_encoding(train_df[classvar])

        return train_df, y_train, test_df, y_test

    def one_hot_encoding(self, y_data):
        """
        Apply one hot encoding to y variable for classification using OneHotEncoder from sklearn.
        """
        # sort the values in categorical y_data
        feature_vec = y_data.sort_values().values.reshape(-1, 1)
        
        # instantiate the encoder and load the y_data features
        enc = OneHotEncoder(handle_unknown='ignore')
        enc.fit(feature_vec)
        
        # run the y_data values through the encoder
        vector = y_data.values.reshape(-1, 1)
        encoded_vec = enc.transform(vector).toarray()
        
        return encoded_vec


    def encode_x(self, df, stringvar):
        """
        Encode the input data.
        
        df = dataframe to be passed to the model
        stringvar = the name of the string variable to be classified
        """

        # 0 indicates padding, 1 indicates beginning of name, letters are the allowed characters in the stringvar
        alphabet = '10abcdefghijklmnopqrstuvwxyz '

        # define a mapping of chars to integers
        char_to_int = dict((c, i) for i, c in enumerate(alphabet))

        # create empty list to store encoded values
        encoded_list = []

        # cycle through data in the integer encode input data
        for string in df[stringvar]:
            integer_encoded = [char_to_int[char] for char in string]
            encoded_list.append([1] + integer_encoded)
            
        # pad the encoded list to create an array
        encoded_arr = sequence.pad_sequences(encoded_list, maxlen=self.maxlen)
        
        return encoded_arr, len(alphabet)


    def train_model(self, X_train, y_train, X_test, y_test):
        """
        Train the model.
        """
        # compute class weights
        class_weights = class_weight.compute_class_weight('balanced',
                                                          np.unique(np.argmax(y_train, axis=1)),
                                                          np.argmax(y_train, axis=1))
        # compile the model
        self.model.compile('adam', 'binary_crossentropy', metrics=['accuracy'])

        checkpointer1 = ModelCheckpoint(monitor='val_acc',
                                        mode="max",
                                        filepath=f"{self.model_fp}_val_acc.hdf5",
                                        verbose=0,
                                        save_best_only=True)
        
        checkpointer2 = ModelCheckpoint(monitor='val_loss',
                                        mode="min",
                                        filepath=f"{self.model_fp}_val_loss.hdf5",
                                        verbose=0,
                                        save_best_only=True)

        # stop the model training early if it reaches minimum loss        
        es = EarlyStopping(monitor='val_loss', mode='min', verbose=1, patience=10)

        history = self.model.fit(X_train,
                                 y_train,
                                 callbacks=[checkpointer1, checkpointer2, es],
                                 verbose=1,
                                 validation_data=(X_test, y_test),
                                 epochs=self.epochs,
                                 batch_size=self.batch_size,
                                 class_weight=class_weights).history

        # save the model
        save_model(self.model, self.model_fp, overwrite=True)
        print(f"Model trained and saved to {self.model_fp}")
        
        return self.model_fp

        
    def evaluate_model(self, X_test, y_test):
        """
        Evaluate the test set.
        
        X_test = input stringvar data from the test set
        y_test = correct test set classifications 
        """
        # evaluate on test set
        y_true = np.argmax(y_test, axis=1)
        y_pred = self.model.predict_classes(X_test, verbose=1)

        f1 = f1_score(y_true, y_pred, average='weighted')
        roc_auc = roc_auc_score(y_true, y_pred, average='weighted')
        cm = confusion_matrix(y_true, y_pred).ravel()
            
        print("F1 score:", f1)
        print("AUC score:", roc_auc)
        print("TN : {}, FP : {}, FN : {}, TP : {}".format(cm[0], cm[1], cm[2], cm[3]))
        
        data_return = {"f1_score": f1, 
                       "roc_auc_score": roc_auc, 
                       "confusion_matrix": cm,
                       "y_test": y_test,
                       "y_pred": y_pred,
                       "X_test": X_test}
        
        return data_return
        
        
    def predict_classes(self, X_data):
        """
        Use a trained model to predict classifications for unlabelled data.
        
        X_data = input stringvar data to be classified by the model
        """
        # use the model to classify data
        y_pred = self.model.predict(X_data, verbose=1)
        
        return y_pred
    
