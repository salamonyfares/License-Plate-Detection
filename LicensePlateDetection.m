%Characters Dataset creation:
%----------------------------
%Writing the path of Images
path1='DataSet\\Numbers\\'; 
path2='DataSet\\Letters\\'; 

%Read all .bmp images in the file by using *
numbers = dir(strcat(path1,'*.bmp'));
letters=dir(strcat(path2,'*.bmp'));

 %Create the cell array that will contain the dataset
 charctersDataset=cell(length(numbers)+length(letters),1);
 
 %Reading the numbers from its path and adding to the cell array
 for i=1:length(numbers)
     charctersDataset{i}=imread(strcat(path1,numbers(i).name));
%    Making sure that there is no RGB image  
     if(size(charctersDataset{i},3)>1)
         charctersDataset{i}=rgb2gray(charctersDataset{i});
     end
     charctersDataset{i}=imresize(charctersDataset{i},[42 24]); %Resizing the images to have the same size and make it easier in comparing
 end
 
  %Reading the letters from its path and adding to the cell array starting
  %at the index that is after the last index reached while adding the numbers
 for i=1:length(letters)
     charctersDataset{length(numbers)+i}=imread(strcat(path2,letters(i).name));
     if(size(charctersDataset{length(numbers)+i},3)>1)
         charctersDataset{length(numbers)+i}=rgb2gray(charctersDataset{length(numbers)+i});
     end
     charctersDataset{length(numbers)+i}=imresize(charctersDataset{length(numbers)+i},[42 24]);
 end
%--------------------------------------------------------
%Application Implementation:
%---------------------------
Img=imread('im1.jpg'); % uploading the test images here

% After reading the image we have to make it ready to do morphological
% operations on it by making it binary image
grayImg=rgb2gray(Img);
binaryImg=~imbinarize(grayImg);
filledImg=imfill(binaryImg,'holes'); % filling any holes to make the image consistant
Plate = bwareaopen(filledImg,200); % doing open operation to make sure that there is no noise in the image
plateProps=regionprops(Plate,'Orientation','BoundingBox'); % taking the region properties of the image to detect the plates 
count = numel(plateProps);
plates = [];
platesRotation = [];

 for i=1:count
     plates = [plates plateProps(i).BoundingBox]; % adding the bounding box property of the plates in the array
     platesRotation = [platesRotation plateProps(i).Orientation];% adding the rotation values property of the plates in the array
 end
 
propsNum = length(plates);
clf

% making two cell arrays that will contain the plates in binary and rgb form 
%(each bounding box property holds four values so if we have one plate in 
% the image then the plates array should be of size 4 and if we have more 
% then it will be of size n/4)
    binaryPlates = cell(propsNum/4,1); 
    coloredPlates = cell(propsNum/4,1);
    
    for i=1 :length(binaryPlates)
%       Cropping the plates from the image and adding them to the cell arrays  
        binaryPlates{i,1} = imcrop(binaryImg, plates(4*i-3:4*i));
        coloredPlates{i,1} = imcrop(Img, plates(4*i-3:4*i));
%       Checking on the rotation values (after alot of testing I found that if the rotation value is more than 20
%       we have to rotate with only half of that value)
        if platesRotation(i)> 20 || platesRotation(i)<-20
            angle=platesRotation(i);
            binaryPlates{i,1}=imrotate(binaryPlates{i,1},-angle/2,'crop');
            coloredPlates{i,1}=imrotate(coloredPlates{i,1},-angle/2,'crop');
            
%       but if the rotation value is between 5 and 20 we rotate it with the same value
        elseif platesRotation(i)> 5 && platesRotation(i) < 20 || platesRotation(i)<-5 && platesRotation(i) > -20
            angle=platesRotation(i);
            binaryPlates{i,1}=imrotate(binaryPlates{i,1},-angle,'crop');
            coloredPlates{i,1}=imrotate(coloredPlates{i,1},-angle,'crop');
%       and if the rotation value is less than 5 then there is no rotation
        else
            binaryPlates{i,1}=binaryPlates{i,1};
            coloredPlates{i,1} = coloredPlates{i,1};
        end
    end
 
    numPlates = length(binaryPlates);
    charactersProps = cell(length(numPlates),1); % this is a cell of cells that will contain the props of every character in every plate
    plateCharacters = cell(length(numPlates),1);% this is a cell of cells that will contain the cropped image of every character in every plate
% Now the images are ready for the requirements of the project which is
% detecting the color of the plate and showing the Charaters and knowing
% the count of the total characters in the plate and the count of the
% numbers in the pate
for i=1:numPlates
%  Phase One: detecting the color of the plate
%  First: we crop the image to get only the top part
    cropHieght = size(coloredPlates{i,1});
    coloredPlates{i,1} = coloredPlates{i,1}(1:ceil(0.36*cropHieght),:,:);
    
%   Second: we retrieve the R G B plates from the cropped image
    redC = coloredPlates{i,1}(:,:,1) ;
    greenC= coloredPlates{i,1}(:,:,2);
    blueC = coloredPlates{i,1}(:,:,3);
    
%   Third: We create 4 images by applying thresholding method, We do that by thresholding
%   the images with color ranges of each possible plate color like :
%   red, orange, light blue, and gray
    orangeRange = redC>250 & greenC>50 & greenC<130 & blueC<20;
    redRange = redC>150 & greenC < 50 & blueC < 50;
    lightBlueRange = redC<90 & greenC>86 & greenC<228 & blueC >130 & blueC <251;
    grayRange = redC>100 & greenC>100& blueC>100 & redC <150 & greenC<150 & blueC<150;
    
%   Fourth: we take the mean value of the thresholded image in order to check for
%   the color of the plate
    meanRed=mean(redRange(:));
    meanLightBlue=mean(lightBlueRange(:));
    meanOrange=mean(orangeRange(:));
    meanGray=mean(grayRange(:));
    
%   Lastly: Here we add the mean values in an array and then retrieve the highest
%   values (the value that corresponds to the true plate color)
    meanValues=[meanRed,meanLightBlue,meanOrange,meanGray];
    plateClr=max(meanValues);

    if plateClr==meanRed
        disp('Transport')
    elseif plateClr==meanLightBlue
        disp('Owners car')
    elseif plateClr==meanOrange
        disp('Taxi')
    elseif plateClr==meanGray
        disp('Government car')
    end
%-------------------------------------------------
% Phase Two: Detecting the Characters and the count of the numbers
%   First: we crop the plate image to get only the bottom part
    height=size(binaryPlates{i,1},1);
    binaryPlates{i,1}= binaryPlates{i,1}(ceil(0.37*height):height,:);
%   Second: We define some variables and perform some moroplogical
%   operations
    SE=strel('disk',1);
    binaryPlates{i,1}=imdilate(binaryPlates{i,1},SE);
    binaryPlates{i,1}=bwareafilt(binaryPlates{i,1},[10 200]);
    charactersProps{i,1}=regionprops(binaryPlates{i,1},'BoundingBox'); % we get the properties of each character in the plate
    plateCharacters{i,1}=cell(length(charactersProps{i,1}),1); % This variable is created to hold the characters after cropping
%   These variables is created for the OCR part
    numberFeatures=cell(length(charactersProps{i,1}),1);
    letterFeatures=cell(length(charactersProps{i,1}),1);
    numberCount=0;
    hold on
%   Third: we go into each plate and perform a set of operations to get the
%   count of the total characters and the count of the numbers
    for j = 1 : length(charactersProps{i,1})
%       we do the operations on each plate character to make it ready for
%       the OCR part
        letterBoundigBox = charactersProps{i,1}(j).BoundingBox;      
        plateCharacters{i,1}{j,1}=imcrop(binaryPlates{i,1},letterBoundigBox);
        plateCharacters{i,1}{j,1}=imerode(plateCharacters{i,1}{j,1},SE);
        plateCharacters{i,1}{j,1}=imresize(plateCharacters{i,1}{j,1},[42 24]); % resizeing each character image to make its size equal the size of the dataset images

%       here is the beginning of the OCR part we start by creating 2 matrices
%       of zeros with the size of each the letters and the numbers
        numberFeatures{j}=zeros(length(numbers),1);
        letterFeatures{j}=zeros(length(letters),1);
%       here we start the comparing between the each plate character and the
%       whole dataset we have by doing corrilation between the images and
%       storing the values in the matrix built earlier
        for t=1:length(numbers)
            numberFeatures{j}(t)=corr2(charctersDataset{t},plateCharacters{i,1}{j});
        end
        
        for b=1:length(letters)
            letterFeatures{j}(b)=corr2(charctersDataset{length(numbers)+b},plateCharacters{i,1}{j});
        end
%       here we take the maximum value found in both matrices and their
%       corresponding index
        maxNumber = max(numberFeatures{j});
        maxLetter = max(letterFeatures{j});
%       here we check weither the plate character is letter or number and
%       act upon it
        if(maxNumber>maxLetter)
            numberCount=numberCount+1;
        end
        
    end
    if length(charactersProps{i,1}) == 6 && numberCount == 3
        disp('Governorate of vehicle: Cairo')
        
    elseif length(charactersProps{i,1}) == 6 && numberCount == 4
        disp('Governorate of vehicle: Giza')
        
    else
        disp('Other Governorate')
    end
end 
%This loop is to print every character in every plate -it is kinda missy
%but this is the best i could reach :) -
itrCount = 1;
for i=1:length(plateCharacters)
    for j = 1:length(plateCharacters{i,1})
        subplot(numPlates,7,itrCount)
        imshow(plateCharacters{i,1}{j,1})
        itrCount = itrCount+1;
    end
end
