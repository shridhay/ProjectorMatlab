% %%%%% Large Retina Map %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% Large Retina Map adapted for Zohreh
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% LargeRetinaMap('test',1.1,1.1,1.1,-2.25,-1) To get to the Top-Left corner of the raster
% Center points placed at (-2.25,-12022HirdTested on 2022-12-14 ,
% Center of the raster tested on 2022-12-15 was (-1.2LargeRetinaMap('10003L',1.1,1.1,1.1,2.875,0)50,0.000)

function LargeRetinaMap(subjID,raster_FOV,width,height,center_x,center_y)
    
    %% PsychToolbox display setup
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference','VisualDebugLevel', 0);
        oldLevel = Screen('Preference', 'Verbosity', 1);

    % Get a window ready
        which_screen = max(Screen('Screens'));
        [w,~] = Screen('OpenWindow',which_screen,[0,0,0]);

        LoadIdentityClut(w); %load in a linear LUT

        Screen('WindowSize',w);

    %% Default temporal parameters
        date = datestr(now, 'yyyymmdd');
        wait_time = 0.1; % delay time between checking for keypresses (in seconds)
        vid_frames = 60; % video length in frames (currently 60 -> 2 sec videos)
        vid_length = vid_frames / 30; % video length in seconds


    %% Define key names
    % [structured after section of the same name in raster_cancel]
        KbName('UnifyKeyNames');
        key_names.next_key = 'RightArrow';
        key_names.prev_key = 'LeftArrow';
        key_names.record_key = 'Space';
        key_names.quit_key = 'Space';
        key_names.enter_key = 'Space';

    % Defining keys after names above
        keys.next_key = KbName(key_names.next_key);
        keys.prev_key = KbName(key_names.prev_key);
        keys.record_key = KbName(key_names.record_key);
        keys.quit_key = KbName(key_names.quit_key);
        keys.enter_key = KbName(key_names.enter_key);


    %% Raster calibration
        temp = load('registration.mat','maps');
        maps = temp.maps;

        fov_width = raster_FOV;
        fov_height = raster_FOV;


    %% Compute the number of images needed in each dimension.
        if width <= 3 * raster_FOV / 2
            if width <= raster_FOV
                N_img = 1;
            else
                N_img = 2;
            end
        else
            N_img = ceil(1 + ((2 * (width - raster_FOV)) / raster_FOV));
        end

        if height <= 3 * raster_FOV / 2
            if height <= raster_FOV
                M_img = 1;
            else
                M_img = 2;
            end
        else
            M_img = ceil(1 + (2 * (height - raster_FOV)) / raster_FOV);
        end

        total_num_pts = N_img * M_img;
        fprintf('\n This retinal map will require a %2.0f x %2.0f image montage. \n\n', N_img, M_img);


    %% Compute fixation point locations for NxM images at img_deg_ecc
    % Initialize fix_pts_SEV abd fix_pts_proj cell arrays, fixation cross params
        fix_pts_proj = cell(M_img, N_img);
        fix_pts_SEV = cell(M_img, N_img);
        fix_length = 8; % fixation cross line length (pixels)
        fix_width = 1; % fixation cross line width (pixels)

    % Calculate N_1,M_1 (top-left fixation point)
        if mod(N_img, 2) == 0
            N_1 = 0 - (((N_img / 2) - 1) * (raster_FOV / 2) + (raster_FOV / 4));
        else
            N_1 = 0 - (((N_img - 1) / 2) * (raster_FOV / 2));
        end

        if mod(M_img, 2) == 0
            M_1 = 0 + (((M_img / 2) - 1) * (raster_FOV / 2) + (raster_FOV / 4));
        else
            M_1 = 0 + (((M_img - 1) / 2) * (raster_FOV / 2));
        end

    % Account for eccentricity
        N_1 = N_1 + center_x;
        M_1 = M_1 + center_y;

    % Populate the rest of the cell array with the remaining fixation pts
        M_curr = M_1;

        for i = 1:M_img
            N_curr = N_1;
            for j = 1:N_img

                % Add point to the fix_pts_SEV cell array
                    fix_pts_SEV(i,j) = {[N_curr,M_curr]};

                % Convert to projector space
                    fix_xy_P = SEVtoP([N_curr;M_curr], fov_width, fov_height, maps);
                    fix_xpos = fix_xy_P(1);
                    fix_ypos = fix_xy_P(2);

                % Add calculated point to the fix_pts_proj cell array
                    fix_pts_proj(i,j) = {[fix_xpos,fix_ypos]};

                N_curr = N_curr + (raster_FOV / 2);
            end
            M_curr = M_curr - (raster_FOV / 2);
        end


    % Initialize screen
        which_screen = max(Screen('Screens'));
        [w,~] = Screen('OpenWindow',which_screen,[0,0,0]);
        Screen('FillRect',w,[0 0 0]);


    %% Set up to begin recording process
        fprintf('Entering imaging mode.\n');
        fprintf('Controls:\nUse the left/right arrow keys to move between fixation points.\n');
        curr_fix_pt = 1;
        record_vid = false;
        update_fix_pt = true;
        vid_num = 1;
        vids_taken = zeros([total_num_pts, 1]);


    % Take NxM videos at the relevant fixation points.
    while curr_fix_pt <= total_num_pts

        %% Update fixation point if prompted
        if update_fix_pt
            update_fix_pt = false; % only update once per keypress

            % Get x,y coordinates for current fixation point.
                curr_fix_coords_proj = fix_pts_proj{curr_fix_pt};
                curr_fix_coords_SEV = fix_pts_SEV{curr_fix_pt};
                curr_fix_x_SEV = curr_fix_coords_SEV(1);
                curr_fix_y_SEV = curr_fix_coords_SEV(2);
                curr_fix_x = curr_fix_coords_proj(1);
                curr_fix_y = curr_fix_coords_proj(2);

            % Present cross 
                Screen('FillRect',w,[0 0 0]);

                % Draw fixation cross
                    x_coords = [curr_fix_x-fix_length, curr_fix_x-2,...
                                    curr_fix_x+2, curr_fix_x+fix_length,...
                                    curr_fix_x, curr_fix_x,...
                                    curr_fix_x, curr_fix_x];
                    y_coords = [curr_fix_y, curr_fix_y,...
                                    curr_fix_y, curr_fix_y,...
                                    curr_fix_y-fix_length, curr_fix_y-2,...
                                    curr_fix_y+2, curr_fix_y+fix_length];
                    coords = [x_coords; y_coords];
                    Screen('DrawLines', w, coords, fix_width); 

                % "Flip" the offscreen graphics buffer to the front so it's
                % visible to the subject.
                    Screen('Flip',w);
                    fprintf('\nDisplaying fixation point %2.0f/%2.0f at (%2.3f,%2.3f). ', curr_fix_pt, total_num_pts, curr_fix_x_SEV, curr_fix_y_SEV);
        end


        %% Check for and deal with key presses
        % [Structured after section of the same name in raster_cancel]
        [keyIsDown,~,keyCode] = KbCheck;
        if keyIsDown == 1
            if keyCode(keys.quit_key)
                sca;
                return;
            else
                [...
                    update_fix_pt,...
                    record_vid,...
                    curr_fix_pt...
                    ] = key_check(...
                    keyCode,...
                    keys,...
                    curr_fix_pt,...
                    total_num_pts,...
                    vids_taken,...
                    wait_time...
                    );
            end
        end
    end

    % Clear the projector display
    sca;

            
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Deal with key presses
function [...
    update_fix_pt,...
    record_vid,...
    curr_fix_pt...
    ] = key_check(...
    keyCode,...
    keys,...
    curr_fix_pt,...
    total_num_pts,...
    vids_taken,...
    wait_time...
    )

%% Set default for each returned variable
    update_fix_pt = false;
    record_vid = false;

%% Handle keypresses
    if ~isempty(keys)
        %% Move to next fixation point
            if keyCode(keys.next_key)
                temp = curr_fix_pt + 1;
                if temp > total_num_pts                                        
                    fprintf('\n\nYou have reached the final fixation point.\n');
                    
                    fprintf('\nPress spacebar to finish.\n');
                else
                    curr_fix_pt = temp;
                    update_fix_pt = true;
                end
                WaitSecs(0.5);

        %% Move to prev fixation point
            elseif keyCode(keys.prev_key)
                temp = curr_fix_pt - 1;
                if temp > 0
                    curr_fix_pt = curr_fix_pt - 1;
                    update_fix_pt = true;
                end
                WaitSecs(0.5);

            
        %% Exit recording mode 
            elseif keyCode(keys.enter_key)
                curr_fix_pt = curr_fix_pt + 1;
             
        %% Pause between keypress checks
            end
            WaitSecs(wait_time);
                
    end
end