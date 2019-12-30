// Tweeter Spam filtering using Logistic Regression with SGD

import org.apache.spark.{sparkConf, SparkContext}
import org.apache.spark.mllib.classification.LogisticRegressionWithSGD
import org.apache.spark.mllib.feature.HashingTF
import org.apache.spark.mllib.regression.LabeledPoint

val spam_mails = sc.textFile("/Users/mamun/hadoop/input/dataset/spam")
val ham_mails = sc.textFile("/Users/mamun/hadoop/input/dataset/ham")

val features = new HashingTF(numFeatures = 1000)

val Features_spam = spam_mails.map(mail => features.transform(mail.split(" ")))
val Features_ham = ham_mails.map(mail => features.transform(mail.split(" ")))

val positive_data = Features_spam.map(features => LabeledPoint(1, features))
val negative_data = Features_ham.map(features => LabeledPoint(0, features))

val data = positive_data.union(negative_data)
data.cache()
val Array(training, test) = data.randomSplit(Array(0.6, 0.4))

val logistic_Learner = new LogisticRegressionWithSGD()

val predictionLabel = test.map(x=> (model.predict(x.features),x.label))

val accuracy = 1.0 * predictionLabel.filter(x => x._1 == x._2).count() / training.count()