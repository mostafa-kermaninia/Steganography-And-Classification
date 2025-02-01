close all;
clc; clear;

% Read images
A = imread('PCB.jpg');
B = imread('IC.png');

ICrecognition(A, B);

function ICrecognition(A, B)

    figure;

    % Display PCB image
    subplot(2, 2, 1);
    imshow(A);
    title('PCB Image');

    % Display IC template image
    subplot(2, 2, 2);
    imshow(B);
    title('IC Image');

    drawnow; % Display changes immediately

    % Display matching result
    subplot(2, 2, [3, 4]);
    imshow(A);
    title('Matching Result');
    hold on;

    % Detect ICs and draw rectangles
    rectangles_original = recognizeAndGetRectangles(A, B);

    % Rotate the template by 180 degrees and detect again
    ic_rotated = imrotate(B, 180);
    rectangles_rotated = recognizeAndGetRectangles(A, ic_rotated);

    % Combine rectangles from both original and rotated templates
    all_rectangles = [rectangles_original; rectangles_rotated];

    % Use Non-Maximum Suppression to eliminate overlapping rectangles
    final_rectangles = no_overlapping(all_rectangles);

    % Draw final rectangles on the matching result image
    for k = 1:size(final_rectangles, 1)
        rectangle('Position', final_rectangles(k, 1:4), 'EdgeColor', 'b', 'LineWidth', 2);
    end

    hold off;
end

% Function to calculate correlation and return similar regions without drawing rectangles
function rectangles = recognizeAndGetRectangles(pcb, ic)
    [rowpcb, colpcb, chnls_pcb] = size(pcb);
    [rowic, colic, ~] = size(ic);

    % Convert the template to double for correlation calculation
    a = double(ic);

    % Variable to store rectangles and their correlation coefficients
    rectangles = [];

    % Loop to identify similar parts in the PCB image
    for i = 1:(rowpcb - rowic)
        for j = 1:(colpcb - colic)
            % Extract sub-image from the PCB
            b = double(pcb(i:(i + rowic - 1), j:(j + colic - 1), :));

            % Calculate correlation coefficient for each channel
            total_coff = 0;
            for c = 1:chnls_pcb
                a_channel = a(:, :, c);
                b_channel = b(:, :, c);

                % Calculate correlation coefficient for channel c
                q = sqrt(sum(sum(a_channel .* a_channel)) * sum(sum(b_channel .* b_channel)));
                p = sum(sum(a_channel .* b_channel));
                coff = p / q;

                % Sum correlation coefficients of all channels
                total_coff = total_coff + coff;
            end

            % Calculate average correlation coefficient
            avg_coff = total_coff / chnls_pcb;

            % Store rectangle if the average correlation coefficient is high enough
            if avg_coff >= 0.9
                rectangles = [rectangles; j, i, colic, rowic, avg_coff];
            end
        end
    end
end


function final_rects = no_overlapping(rects)
    % Initialize an empty array for the final rectangles
    final_rects = [];

    while ~isempty(rects)
        % Select the rectangle with the highest correlation coefficient
        [~, max_idx] = max(rects(:, 5));
        current_rect = rects(max_idx, :);
        final_rects = [final_rects; current_rect];

        % Remove the selected rectangle
        rects(max_idx, :) = [];
        overlapIdx = [];

        % Identify rectangles that have significant overlap with the selected one
        for i = 1:size(rects, 1)
            if overlap(current_rect, rects(i, :)) > 0.3 % Threshold for overlap (30%)
                overlapIdx = [overlapIdx; i];
            end
        end

        % Remove overlapping rectangles
        rects(overlapIdx, :) = [];
    end
end

% Function to calculate the overlap ratio between two rectangles
function ratio = overlap(rect1, rect2)
    % Calculate overlap coordinates
    x_overlap = max(0, min(rect1(1) + rect1(3), rect2(1) + rect2(3)) - max(rect1(1), rect2(1)));
    y_overlap = max(0, min(rect1(2) + rect1(4), rect2(2) + rect2(4)) - max(rect1(2), rect2(2)));

    % Calculate overlap area
    overlap_area = x_overlap * y_overlap;

    % Calculate areas of both rectangles
    area1 = rect1(3) * rect1(4);
    area2 = rect2(3) * rect2(4);

    % Calculate the overlap ratio relative to the smaller rectangle area
    ratio = overlap_area / min(area1, area2);
end
