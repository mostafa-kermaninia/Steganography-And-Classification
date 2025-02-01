%% Part 1
% Define our char array which contains alphabet and additional characters
chars = ['a':'z', ' ', '.', ',', '!', '"', ';'];

% Creating a mapset with 2 rows and columns Row 1 is the characters Row 2
% is the binary coded value of each character
Mapset = cell(2, 32);

% Set the values into Mapset
for i = 1:32
    % Store the character in the first row of Mapset
    Mapset{1, i} = chars(i);
    
    % Add the binary coded value for each character (i-1 in binary)
    Mapset{2, i} = dec2bin(i - 1, 5);
end


%% part 3

% Write a message
MESSAGE = 'signal;';

% Read the picture
FORMAT = ".png";
FILE_TO_READ = 'Amsterdam';
pic = imread(FILE_TO_READ + FORMAT);

% Make the picture gray
pic_gray = rgb2gray(pic);
GRAY_FILE = FILE_TO_READ + "_gray" + FORMAT;
imwrite(pic_gray,GRAY_FILE);

% Encode message in picture
coded_pic = coding(MESSAGE, GRAY_FILE, Mapset);
ENCODED_FILE = FILE_TO_READ + "_encoded" + FORMAT;
imwrite(coded_pic,ENCODED_FILE);

% Show both original and coded picture
figure;
subplot(1,2,1);
imshow(pic_gray);
title('Original PIC');
subplot(1,2,2);
imshow(coded_pic);
title('Coded PIC');


%% test part 4
decoded_msg = decoding(ENCODED_FILE,Mapset, 1000);

%% part 2
function coded_pic = coding(message, gpic, mapset)

    threshold = 1000;
    % Load the grayscale image
    imgGray = imread(gpic);
    [rows, cols] = size(imgGray);  % Image dimensions

    % Define a list to store the selected boxes with variance above the threshold
    selectedBlocks = [];

    % Loop through the image with a sliding 25x25 window
    for i = 1:25:(rows - 24)
        for j = 1:25:(cols - 24)
            % Extract 25x25 window and calculate its variance
            window = imgGray(i:i+24, j:j+24);
            variance = var(double(window(:)));

            % Select the box if its variance is above the threshold
            if variance > threshold
                selectedBlocks = [selectedBlocks; i, j];
            end
        end
    end

    % Display number of selected 25x25 boxes
    disp(['Selected 25x25 blocks: ', num2str(size(selectedBlocks, 1))]);

    % Convert message to binary sequence using mapset
    message_bin = '';
    for k = 1:length(message)
        char_index = find(strcmp(mapset(1,:), message(k)));  % Find the character index in mapset
        if isempty(char_index)
            error(['Character ', message(k), ' not found in mapset.']);
        end
        char_bin = mapset{2, char_index};  % Get binary representation of each character
        message_bin = [message_bin, char_bin];  % Append to the binary message sequence
    end

    % Check if there is enough space in selected boxes to embed the message
    total_bits_available = numel(selectedBlocks) * 25 * 25;  % Total bits in all selected 25x25 boxes
    if length(message_bin) > total_bits_available
        error('Message is too long to fit in the selected areas.');
    end
    
    % Initialize the coded picture as a copy of the original image
    coded_pic = imgGray;
    msg_idx = 1;  % Pointer for binary message bits

    % Embed binary message in selected boxes
    for block = 1:size(selectedBlocks, 1)
        if msg_idx > length(message_bin)
            break;  % Stop if all message bits are embedded
        end

        % Get top-left corner of the 25x25 box
        i = selectedBlocks(block, 1);
        j = selectedBlocks(block, 2);

        % Embed message bits in the least significant bit of each pixel in the box
        for m = 0:24
            for n = 0:24
                if msg_idx > length(message_bin)
                    break;  % Stop if all message bits are embedded
                end
                pixel_val = coded_pic(i + m, j + n);  % Get pixel value
                pixel_bin = dec2bin(pixel_val, 8);  % Convert to 8-bit binary

                % Replace least significant bit with message bit
                pixel_bin(end) = message_bin(msg_idx);  
                coded_pic(i + m, j + n) = bin2dec(pixel_bin);  % Update pixel in coded image

                msg_idx = msg_idx + 1;  % Move to the next bit in the message
            end
        end
    end
end



%% part 4
function decoded_msg = decoding(coded_pic, mapset, threshold)

    % Read the encoded grayscale image
    imgGray = imread(coded_pic);
    [rows, cols] = size(imgGray);  % Image dimensions

    % Define a list to store selected boxes with variance above the threshold
    selectedBlocks = [];

    % Loop over the image using a sliding 25x25 window to find areas with variance above threshold
    for i = 1:25:(rows - 24)
        for j = 1:25:(cols - 24)
            % Extract a 25x25 window and calculate its variance
            window = imgGray(i:i+24, j:j+24);
            variance = var(double(window(:)));

            % Select the box if its variance is above the threshold
            if variance > threshold
                selectedBlocks = [selectedBlocks; i, j];
            end
        end
    end

    % Display the number of selected 25x25 boxes
    disp(['Selected 25x25 blocks for decoding: ', num2str(size(selectedBlocks, 1))]);

    % Initialize an array to store decoded binary message
    binary_message = '';
    flag = true;  % flag for knowing if still we have to decode or not

    % Start decoding the embedded message from each selected box
    for block = 1:size(selectedBlocks, 1)
        if ~flag
            break;  % Stop if the end of the message is reached
        end
        % Get top-left corner of the current 25x25 box
        i = selectedBlocks(block, 1);
        j = selectedBlocks(block, 2);
        % Extract bits from the least significant bits of each pixel in the 25x25 box
        for m = 0:24
            for n = 0:24
                if ~flag
                    break;  % Stop if the end of the message is reached
                end
                % Get pixel value and extract the least significant bit
                pixel_val = imgGray(i + m, j + n);
                pixel_bin = dec2bin(pixel_val, 8);  % Convert to 8-bit binary
                binary_message = [binary_message, pixel_bin(end)];  % Append LSB to message

                % Check if we've completed a 5-bit character
                if mod(length(binary_message), 5) == 0
                    % Convert 5 bits to a character based on mapset
                    char_bin = binary_message(end-4:end);  % Get the last 5 bits
                    char_idx = bin2dec(char_bin) + 1;  % Convert binary to decimal index
                    % Check if the character is the terminator ';'
                    if strcmp(mapset{1, char_idx}, ';')
                        flag = false;  % End of message
                        decoded_msg_chars{(length(binary_message) / 5)} = mapset{1, char_idx};
                    else
                        % Append character to the decoded message
                        decoded_msg_chars{(length(binary_message) / 5)} = mapset{1, char_idx};
                    end
                end
            end
        end
    end

    % Convert cell array to string and display the decoded message
    decoded_msg = strjoin(decoded_msg_chars, '');
    disp(['Decoded Message: ', decoded_msg]);
end



    
    
    