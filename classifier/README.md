To classify litigant and judge names by gender and religion in our paper on  [In-group bias in the Indian judiciary](http://paulnovosad.com/pdf/india-judicial-bias.pdf), 
we developed and applied a machine classifier that reads name strings and assigns probabilities of names belonging to female/male or Muslim/non-Muslim individuals.
Specifically, we trained a Character-level Bidirectional Long Short-Term Memory (LSTM) network model. The LSTM is a specific type of Recurrent Neural Network which 
reads over name characters and interprets them based on a “memory” of the history of characters.

We trained the LSTM classifier on two large underlying datasets containing millions of names mapped to identities. To classify gender, we use a dataset of 13.7 million names with labeled gender from the Delhi voter
rolls. To classify religion, we use a database of 1.4 million names with a religion label for individuals who sat for the National Railway Exam. The resulting model 
to classify name strings by gender is saved found in the zipped replication packet dataset [here](https://drive.google.com/file/d/1N_7vKKRDiBHhMZT5eRqNszR1aksMrlJd/view) as 
`delhi_names_gender.hdf5`. For those interested in using the underlying religion classifier, we request you to get in touch with us for access.

The gender classifier model and a sub-set of 10,000 random names have been provided in the replication data packet to illustrate how the LSTM classifier built for our study works. These are called in by `classifier/classify_names.do` in addition to program functions in `classifier/classify_names.py` for the gender
name classification process.

Additional details about the LSTM network, underlying training data and accuracy measures can be found in our [paper here](http://paulnovosad.com/pdf/india-judicial-bias.pdf).
