import math
import sys
import string
#import matplotlib.pyplot as plt
import numpy as np
#import perceptron
#from matplotlib import cm

#globals
# global numpy array where row is class and col is weights of pixels for class
weight_ary = np.zeros(shape=(10,784)) 
bias_ary = np.zeros(shape=(10,1))



# init_weights
# function: initialized weight of every class in a large numpy array
# Input: init_value: how you want to initializes
# Output: None
# Effect: Updates large global numpy array  
def init_weights(init_value):
    print("init_value=",init_value)
    global weight_ary
    if init_value == "random":
        weight_ary = np.random.randn(10,784) # TODO: play with range -1 to 1 or something bigger  
    elif init_value == "zero":
        weight_ary = np.zeros(shape=(10,784))
    print('asdisand',weight_ary)
    return



# convert_list
# function: converts 1d list of #,+, and " " to a numpy array of 1's and zero's
# Input: bitmap
# Output: numpy array to be returned
def convert_list(bitmap):
    temp = [] 
    for el in bitmap:
        if el == " ":
            temp.append(0)
        elif el == "+":
            temp.append(1)
        else:
            temp.append(1)
    #print("temp:",temp)
    convert_bitmap = np.array(temp)
    return convert_bitmap



# classify_image
# Function: determine if image is classified correctly use for training image
# Input: label 
#        bitmap_np
# Output: whether image was classified correctly or not (boolean)    
def classify_image(label, bitmap_np):
    global weight_ary 
    global biar_ary 
    dot_product = np.dot(weight_ary,bitmap_np)
    result = np.add(dot_product, bias_ary)
    prediction = np.argmax(result, axis=0) # what we think the class of current training image is
    #print("prediction =", prediction.item(0),",label actually =", label) # always be 1 element and 1d numpy array 

    if int(label) == int(prediction.item(0)): 
        return True, prediction.item(0)
    else:
        return False, prediction.item(0)


# update
# function: classified training image incorrectly. update the weights first. then update the bias. 
# input:    result 
#           bitmap_np
#           epoch_curr
#           label 
# output:
#
def update(bitmap_np, epoch_curr, label, guess, bias_on ):
   # TODO: SHOULD IT BE 1000 or 5000? i noticed training label size = 5000 and test label =1000??????
    alpha = 1000.00/(1000.00+epoch_curr)

    alpha_x = alpha*bitmap_np #784 by 1 matrix
    alpha_x.shape = (1,784)#transpose it to a 1 x 784 
    # update weights
    global weight_ary
    weight_ary[label] = weight_ary[label] + alpha_x
    weight_ary[guess] = weight_ary[guess] - alpha_x
    
    #update bias, if bias toggle is on 
    if bias_on == 'true':
        global bias_ary        
        bias_ary[label] = bias_ary[label] + alpha
        bias_ary[guess] = bias_ary[guess] - alpha 
    
    return 


# training 
# function: Cycle through training examples in multiple passes (epochs) and determine whether to update weights
#           update every classes weight, i think ?????????????????? 
# Input: train_label
#        train_test
#        bias_on
#        epoch_curr 
# Output: None
# Effect: Updates or not the weights depending on whether it classifies it corretly 
def training(train_labels, train_images, bias_on, epoch_curr):    
    total_counter = 0
    correct_counter = 0

    for label in train_labels:
        bitmap = []
        #bitmap_2d = []
        for i in range(0,28):
                tmp_line = train_images.readline().replace('\n', '')
                bitmap.extend( tmp_line )    
        #convert image to numpy array             
        bitmap_np = convert_list(bitmap)
        bitmap_np.shape = (784,1)# make sure x is 784 by 1 
        #TODO: cycle through this training example and  classify example .
        #       if classified correctly, do nothing, else update weights of every class i think
        # 1st step: classify training instance bitmap_np with current weights. think this is dot product
        #           update bias when we have to update weights initially bias is 0. so that we don't have a bias towards
        #           classifying a number  
        accurate, guess = classify_image(label,bitmap_np) 
        if accurate:
            # classified correctly, do not do anything
            correct_counter += 1
        else:
             update(bitmap_np,epoch_curr, int(label), guess, bias_on)# update weights and bias
        #break #  TODO: get rid of break
        total_counter += 1

    #TODO: put the print statement below this as a table or a dictionary format part of report 
    #      we need Training curve: overall accuracy on the training set as a function of the epoch 
    #      (i.e., complete pass through the training data). It's fine to show this in table form.
    print("total correct for epoch #", epoch_curr, " = ", correct_counter,"/", total_counter )
    return 


# TODO: actually test the data 
# testing
# function: after training is done, this function is called to use the multiclass perceptrons on the 
#           testing images and check how good it worked 
# input:    test_images
#           test_labels
# output:   percent correct -overall accuracy on the test set 
#           confusion matrix 
def testing( test_images, test_labels ):
    total_counter = 0
    correct_counter = 0
    
    #initialize 2d confusion matrix==================
    confusion = []
    numb_cnt =  []
    
    for r in range(0,10):
        sub_list = []     
        numb_cnt.append(0) # frequency of how many times i've seen the number label         
        for c in range(0,10):
            sub_list.append(0)
        confusion.append(sub_list)
    #================================================   

    for label in test_labels:
        bitmap = []
        #bitmap_2d = []
        for i in range(0,28):
                tmp_line = test_images.readline().replace('\n', '')
                bitmap.extend( tmp_line )    
        #convert image to numpy array             
        bitmap_np = convert_list(bitmap)
        bitmap_np.shape = (784,1)# make sure x is 784 by 1 

        accurate, guess = classify_image(label,bitmap_np)
        #update matrix with frequency of what you predicted vs what it was 
        confusion[int(label)][guess] += 1.00
        numb_cnt[int(label)] +=1 # total number of labels actually seen of that number
        if accurate:
            # classified correctly this many labels
            correct_counter += 1
        # how many labels there are                 
        total_counter += 1
    
    #Printing Statistics
    print("overall accuracy for testing:", correct_counter,"/", total_counter )
    for actual_num, freq_cnt in enumerate(numb_cnt): 
        confusion[actual_num] =[confusion[actual_num][idx] /freq_cnt for idx,el in enumerate(confusion[actual_num])]
    
    print("confusion matrix (rounded to 3 decimal places)")    
    for el in confusion:
            print([" %0.3f" % entry for entry in el ])
    return 

def main():
    if len(sys.argv) != 4 :
        print("\nusage is case-sensitive: python create_model.py <random or zero> <true or false> <total epoch>")
        print("See Readme for more information\n")
        return

    testimages = "digitdata/" + "testimages"
    testlabels = "digitdata/" + "testlabels"
    trainingimages = "digitdata/" + "trainingimages"
    traininglabels = "digitdata/" + "traininglabels"    
    print("This function generates statistics for Digit Classification")
    
    #step 1: initialize weights
    init_value = sys.argv[1] # Toggle:random or zeros or something else   
    init_weights(init_value)
    global weight_ary
    print("weight_ary:",weight_ary)
    bias_on = sys.argv[2] #True
    #step 2: cycle through training examples & step 3: update weights or do nothing
    epoch_curr = 0 # does epoch start at 1 or 0?  another way of saying is :can learning rate = 1 initially?
    epoch_to_reach = int(sys.argv[3])
    while epoch_curr != epoch_to_reach:
        train_images = open( trainingimages )
        train_labels = open( traininglabels )
        training(train_labels, train_images, bias_on, epoch_curr)
        epoch_curr += 1
    print("DONE TRAINING!")

    #step3: use the weight_ary and bias_ary after training on the test_set 
    test_images = open( testimages )
    test_labels = open( testlabels )
    testing(test_images, test_labels)
    print("DONE TESTING!")
if __name__ == "__main__":
    main()

# Questions: 
# array + C - np.log(np.sum(np.exp(array + C))) <- this is softmax
# when do we use softmax in our implementation? 