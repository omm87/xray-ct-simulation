
function forward_backprojection_GUI2
     hFig = figure('Name', 'Forward and Backprojection GUI', 'NumberTitle', 'off', ...
        'Position', [100, 100, 800, 600]);

    hAxesForward = axes('Parent', hFig, 'Position', [0.1 0.6 0.35 0.35]);
    title(hAxesForward, 'Forward Projection Output');

    hAxesBack = axes('Parent', hFig, 'Position', [0.55 0.6 0.35 0.35]);
    title(hAxesBack, 'Backprojection Output');

    uipanel('Parent', hFig, 'Title', 'Forward Projection', 'FontSize', 10,'Position', [0.05 0.35 0.9 0.2]);
     
    uicontrol('Parent', hFig, 'Style', 'text', 'String', 'Image File:', 'Position', [50, 250, 80, 20]);
       
    hImageFile = uicontrol('Parent', hFig, 'Style', 'edit','Position', [150, 250, 400, 25]);

    uicontrol('Parent', hFig, 'Style', 'text', 'String', 'Step Size:',  'Position', [50, 200, 80, 20]);
       
    hStepSize = uicontrol('Parent', hFig, 'Style', 'edit','Position', [150, 200, 100, 25]);

    uicontrol('Parent', hFig, 'Style', 'text', 'String', 'Num of t-values:','Position', [280, 200, 120, 20]);
    
    hNumT = uicontrol('Parent', hFig, 'Style', 'edit',    'Position', [400, 200, 100, 25]);

    uicontrol('Parent', hFig, 'Style', 'pushbutton', 'String', 'Run Forward Projection','Position', [550, 200, 200, 25], 'Callback', @runForwardProjection);

    % Backprojection Panel
    uipanel('Parent', hFig, 'Title', 'Backprojection', 'FontSize', 10,  'Position', [0.05 0.05 0.9 0.25]);

    uicontrol('Parent', hFig, 'Style', 'text', 'String', 'Reconstruction Size [rows, cols]:',   'Position', [50, 150, 200, 20]);
 
    hReconSize = uicontrol('Parent', hFig, 'Style', 'edit', 'Position', [260, 150, 200, 25]);

    uicontrol('Parent', hFig, 'Style', 'text', 'String', 'Filter Type:',  'Position', [50, 100, 100, 20]);
   
    hFilterType = uicontrol('Parent', hFig, 'Style', 'popupmenu', 'String', {'No Filter', 'Ramp Filter', 'Ramp + Hamming'}, 'Position', [150, 100, 150, 25]);

    uicontrol('Parent', hFig, 'Style', 'text', 'String', 'Input Data Source:',  'Position', [50, 50, 150, 20]);

    hDataSource = uicontrol('Parent', hFig, 'Style', 'popupmenu', 'String', {'Use Forward Projection', 'Load .txt File'},  'Position', [200, 50, 200, 25]);

    uicontrol('Parent', hFig, 'Style', 'pushbutton', 'String', 'Run Backprojection','Position', [550, 50, 200, 25], 'Callback', @runBackprojection);

    % Shared Data
    forwardProjectionData = []; % Store forward projection data

    % Callback for Forward Projection
    function runForwardProjection(~, ~)
        % Get inputs
        imageFile = get(hImageFile, 'String');
        stepSize = str2double(get(hStepSize, 'String'));
        numT = str2double(get(hNumT, 'String'));

        if isempty(imageFile) || isnan(stepSize) || isnan(numT)
            errordlg('Please enter valid inputs for forward projection.', 'Input Error');
            return;
        end

        % Run the forward projection
        try
            forwardProjectionData = forward_projection(imageFile, stepSize, numT);
            plot(hAxesForward, linspace(-1, 1, size(forwardProjectionData, 2)), forwardProjectionData');
            title(hAxesForward, 'Forward Projection Output');
            xlabel(hAxesForward, 't (distance)');
            ylabel(hAxesForward, 'Projection Value');
            msgbox('Forward projection completed.', '');
        catch ME
            errordlg(['Error during forward projection: ', ME.message], 'Error');
        end
    end

    % Callback for Backprojection
    function runBackprojection(~, ~)
        % Get inputs
        reconSize = str2num(get(hReconSize, 'String')); %#ok<ST2NM>
        filterType = get(hFilterType, 'Value');
        dataSource = get(hDataSource, 'Value');

        if isempty(reconSize) || length(reconSize) ~= 2
            errordlg('Please enter a valid reconstruction size.', 'Input Error');
            return;
        end

        % Load data based on source
        if dataSource == 1
            if isempty(forwardProjectionData)
                errordlg('No forward projection data, run forward projection.', 'Data Error');
                return;
            end
            projectionData = forwardProjectionData;
        else
            [fileName, filePath] = uigetfile('*.txt', 'Select a .txt file');
            if fileName == 0
                return; % User canceled file selection
            end
            try
                projectionData = [filePath, fileName];
            catch ME
                errordlg(['Error loading .txt file: ', ME.message], 'File Error');
                return;
            end
        end

        % Run the backprojection
        try
            reconstructedImage = backprojection(projectionData, reconSize, filterType);            
            imagesc(hAxesBack, reconstructedImage);
            colormap(hAxesBack, 'gray');
            colorbar(hAxesBack);            
            msgbox('Backprojection completed.', '');
        catch ME
            errordlg(['Error during backprojection: ', ME.message], 'Error');
        end
    end

    
end

function projection = forward_projection(image, stepsize, num_t)

    data = load(image);
    image = cell2mat(struct2cell(data));
    imshow(image);
    
    [r, c] = size(image);
    M = max(r, c); 
    
    theta_values = linspace(0, 180 - stepsize, 180/stepsize);  % angles from 0° to 180°-stepsize (since projection data of 0° = 180° )
    % t_values = linspace(-M / sqrt(2), M / sqrt(2), num_t);  % distance range 

        t_values = linspace(-M / sqrt(2), M / sqrt(2), num_t);
    if mod(num_t, 2) == 1
        t_values = t_values - (t_values(ceil(num_t/2)) - 0); % Shift so center aligns with 0
    end

    
    projection = zeros(length(theta_values), num_t); % the projection matrix to store results, with dimensions matching the # of angles and t-values.
    
     for j = 1:length(theta_values)  % loop over θ values
        theta = theta_values(j);
        
         for i = 1:num_t  % Loop over t valuesmse

            t = t_values(i);
    
            points = []; % stores points from the x-loop
               
            x = -M/2:M/2; % defines horizontal span
            y_x = (t - x * cosd(theta)) / sind(theta); % calculation of x based y's
            true_x = find(abs(y_x) <= r/2); % only includes the y_x's smaller than abs(rows/2) of image
     
            y = -M/2:M/2; % defines vertical span
            x_y = (t - y * sind(theta)) / cosd(theta); % calculation of y based x's
            true_y = find(abs(x_y)<= c/2); % only includes the x_y's smaller than abs(rows/2) of image
    
            points_x = [x(true_x)', y_x(true_x)']; % satisying conditions for x points
            points_y =[x_y(true_y)', y(true_y)'];  % satisying conditions for y points
          
            points=[points_x;points_y]; % combining both conditioned sets to a single matrix
            
            sorted_points = sortrows(points); 
            sorted_points = unique(sorted_points, 'rows'); % removes duplicate rows based on both columns (x, y)
    
            num_points = length(sorted_points(:,1))-1; % # of rows in sorted_points
    
            %defining storage elements
            distances = zeros(1,num_points-1); % stores distances between consequtive points
            mid_x = zeros(1,num_points-1); %stores mid point x's of consequtive points
            mid_y = zeros(1,num_points-1); %stores mid point y's of consequtive points
            
         
                         for z = 1:(num_points - 1) % -1 since # of consequtive terms                         
                           
                                x1 = sorted_points(z, 1); % taking value from the first column x
                                x2 = sorted_points(z + 1, 1); 
                                y1 = sorted_points(z, 2); % taking value from the second column y                        
                                y2 = sorted_points(z + 1, 2);
                               
                                % scalar elements adding terms wrt z in storage
                                % arrays
                                distances(z) = sqrt((x2 - x1)^2 + (y2 - y1)^2); 
    
                                mid_x(z) = (x2 + x1)/2;
                                mid_y(z)=  (y2 + y1)/2;                        
                         end      
                    
                         row_idx = ((M / 2) - floor(mid_y)); % detecting the address of rows.
                         col_idx = ((M / 2) + ceil(mid_x));  % detecting the address of columns.   
                       
                
                        % Ensure that row_data and column_data are within the valid bounds
                        row_idx = max(1, min(r, round(row_idx))); 
                        col_idx = max(1, min(c, round(col_idx))); 
                
                         
                          % loop through all the rows and add the product of distance and attenuations to the projection.
                         for n = 1:length(row_idx) 
                            projection(j,i) = projection(j,i) + distances(n)*image(row_idx(n),col_idx(n));
                         end        
           end                                    
     end  
            

      
end

function reconstructed_image = backprojection(data, recons_img_size, filter)

if isa(data, 'char') || isa(data, 'string')
    [~, ~, extension] = fileparts(data);
    switch extension
        case '.mat'
            loaded_data = load(data);
            projection_data = loaded_data.projection_data; % if data from .mat file
        case '.txt'
            fileID = fopen(data, 'r');
            num_projections = fscanf(fileID, '%d', 1);
            num_samples = fscanf(fileID, '%d', 1);
            projection_data = zeros(num_projections, num_samples);
            for proj_idx = 1:num_projections
                fscanf(fileID, '%d', 1); % Skip the projection index
                projection_data(proj_idx, :) = fscanf(fileID, '%f', num_samples); 
            end
            fclose(fileID);
        otherwise
            error('Unsupported format, use a .txt file.');
    end
else
    projection_data = data; % Assign input data directly if it is already in matrix form
end

[num_angles, num_beams] = size(projection_data);
r = recons_img_size(1);
c = recons_img_size(2);
M = max(r,c);

theta_values = linspace(0, 180-(180/num_angles), num_angles);  % angles from 0° to 180°-stepsize (since projection data of 0° = 180° )

t_values = linspace(-M / sqrt(2), M / sqrt(2), num_beams);
              if mod(num_beams, 2) == 1
              t_values = t_values - (t_values(ceil(num_beams/2)) - 0); % Shift so center aligns with 0
              end

% Define grid for reconstruction
    x = -c/2:c/2;
    y = -r/2:r/2;

    % Initialize the reconstructed image
    reconstructed_image = zeros(r, c);

 % Apply filtering (if needed)
    if filter > 1
        % Ramp filter
        freqs = linspace(-1, 1,  num_beams);
        ramp_filter = abs(freqs); 
        
        % Apply window if specified
        if filter == 3
            % Hamming window
            window = hamming( num_beams)';
            ramp_filter = ramp_filter .* window;
        end
        
        % Filter each projection slice
        for i = 1:num_angles
            proj_fft = fftshift(fft(projection_data(i, :))); % FFT of projection
            proj_fft = proj_fft .* ramp_filter; % Apply filter
            projection_data(i, :) = real(ifft(ifftshift(proj_fft))); % Inverse FFT            
        end
    end

for j = 1:length(theta_values)  % loop over θ values
        theta = theta_values(j);
        
         for i = 1:num_beams  % Loop over t values
            t = t_values(i);
    
            points = []; % stores points from the x-loop
               
            x = -M/2:M/2; % defines horizontal span
            y_x = (t - x * cosd(theta)) / sind(theta); % calculation of x based y's
            true_x = find(abs(y_x) <= r/2); % only includes the y_x's smaller than abs(rows/2) of image
     
            y = -M/2:M/2; % defines vertical span
            x_y = (t - y * sind(theta)) / cosd(theta); % calculation of y based x's
            true_y = find(abs(x_y)<= c/2); % only includes the x_y's smaller than abs(rows/2) of image
    
            points_x = [x(true_x)', y_x(true_x)']; % satisying conditions for x points
            points_y =[x_y(true_y)', y(true_y)'];  % satisying conditions for y points
          
            points=[points_x;points_y]; % combining both conditioned sets to a single matrix
            
            sorted_points = sortrows(points); 
            sorted_points = unique(sorted_points, 'rows'); % removes duplicate rows based on both columns (x, y)
    
            num_points = length(sorted_points(:,1))-1; % # of rows in sorted_points
    
            %defining storage elements
            distances = zeros(1,num_points-1); % stores distances between consequtive points
            mid_x = zeros(1,num_points-1); %stores mid point x's of consequtive points
            mid_y = zeros(1,num_points-1); %stores mid point y's of consequtive points
            
         
                         for z = 1:(num_points - 1) % -1 since # of consequtive terms                         
                           
                                x1 = sorted_points(z, 1); % taking value from the first column x
                                x2 = sorted_points(z + 1, 1); 
                                y1 = sorted_points(z, 2); % taking value from the second column y                        
                                y2 = sorted_points(z + 1, 2);
                               
                                % scalar elements adding terms wrt z in storage
                                % arrays
                                distances(z) = sqrt((x2 - x1)^2 + (y2 - y1)^2); 
    
                                mid_x(z) = (x2 + x1)/2;
                                mid_y(z)=  (y2 + y1)/2;                        
                         end      
                    
                         row_idx = ((M / 2) - floor(mid_y)); % detecting the address of rows.
                         col_idx = ((M / 2) + ceil(mid_x));  % detecting the address of columns.   
                       
                
                        % Ensure that row_data and column_data are within the valid bounds
                        row_idx = max(1, min(r, round(row_idx))); 
                        col_idx = max(1, min(c, round(col_idx))); 

            for k = 1:length(row_idx)
                reconstructed_image(row_idx(k),col_idx(k)) = reconstructed_image(row_idx(k),col_idx(k)) + projection_data(j,i)*distances(k);
            end

         end
end


    reconstructed_image = reconstructed_image / num_angles;

end

