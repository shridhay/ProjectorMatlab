%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function which allows subject to map between SLO- and projector-
% coordinate spaces. Subject moves first projector point to top left corner
% of SLO raster. Subject moves second projector point to bottom right
% corner of SLO raster.

function maps = Proj_SLO_Registration


% clear; close all;
Screen('Preference', 'SkipSyncTests', 1);

%try
    %% Set initial flags
    use_cal_file = 1; % use calibration file?
    update_display = 1; % display will update on startup
    
%     %% Load calibration file
%     if use_cal_file == 1
%         load cal_03_09_21.mat; %#ok<LOAD>
%     end
    
    %% Collect user input
    commandwindow;
    
    %% Get a window ready
    which_screen = max(Screen('Screens'));
    
    [w,rect] = Screen('OpenWindow',which_screen);
    
    bits_scalar = 255;
    
    LoadIdentityClut(w); %load in a linear LUT
%     
%     if use_cal_file == 1
%         Screen('LoadNormalizedGammaTable',w,cal.lookup_table);
%     end
%     
    [screen_width, screen_height] = Screen('WindowSize',w);
    
    smx = round(screen_width/2);
    smy = round(screen_height/2);
    
    %% Define key names
    
    % Instantiate a gamePad object
    gamePad = GamePad();

    
    %% Default spatial parameters
    
    % all of the parameters here, except when otherwise noted, are in
    % pixels

    
    sp.default_fix_xpos = smx + 50;
    sp.default_fix_ypos = smy + 50;
    
    sp.fix_width = 1;
    sp.fix_length =8;
    sp.fix_half_length = ceil(sp.fix_length / 2);
    sp.move_step = 1;
    sp.fix_rgb = [255 255 255];

    

    
    sp.field_size = 0.9; %size of the raster in degrees
    
    %% Default temporal parameters
    wait_time = 0.3; %delay time between key checks, in seconds
    
    %% Default color parameters
    sp.bg_rgb = [0, 0, 0]; % background RGB

    


    fix_xpos = sp.default_fix_xpos;
    fix_ypos = sp.default_fix_ypos;

    bg_rgb = sp.bg_rgb;
    
    
    choice_num = 1;
    init_i = 0.01; % uniform raster strength
    x1 = 0;
    y1 = 0;
    x2 = 0;
    y2 = 0;
    fix_rgbs = [200 0 0; 100 100 0; 0 0 0];


    %% Begin task
    all_done = false;
    while all_done == false
        % display_legend(key_names)
        %% turn on uniform SLO raster
%         % 2 for green channel, bounds are 0 to 1
%         SetRasterFixedRectangleParams(2,init_i,0,1,0,1, true);
%         SetDisplayMode(2,'raster-fixed');
        
        move_on = false;
        while move_on == false
            
            if update_display == 1
                %update_display = 0; %only update on startup, and once per settings change

                    %% Draw point 


                    % Draw background (it's a big rectangle)
                    Screen('FillRect',w,bg_rgb); %background


                    % Draw fixation cross
                    x_coords = [fix_xpos-sp.fix_length, fix_xpos+sp.fix_length,...
                        fix_xpos, fix_xpos];
                    y_coords = [fix_ypos, fix_ypos, fix_ypos-sp.fix_length,...
                        fix_ypos+sp.fix_length];
                    coords = [x_coords; y_coords];
                    Screen('DrawLines', w, coords, sp.fix_width, fix_rgbs(choice_num,:)); 

                    % "Flip" the offscreen graphics buffer to the front so it's
                    % visible to the subject.
                    Screen('Flip',w);

                
            end
            
            %% Check for key presses
            key = gamePad.getKeyEvent();
                if choice_num == 3
                
                    
                    LoadIdentityClut(w);
                    Screen('CloseAll');
                    maps = [x1, y1, x2, y2];
                    % save maps to a file for use from session-to-session
                    save('registration.mat','maps');
                    
                    return;
                    
                else
                    
                    % deal with key presses
                    [...
                        key,...
                        fix_xpos,...
                        fix_ypos,...
                        wait_time,...
                        choice_num,...
                        x1,...
                        y1,...
                        x2,...
                        y2...
                        ] = key_check(...
                        key,...
                        fix_xpos,...
                        fix_ypos,...
                        wait_time,...
                        choice_num,...
                        x1,...
                        y1,...
                        x2,...
                        y2,...
                        sp...
                        ); %#ok<*ASGLU>

                end
        end
            
            
    end
    
%catch ME
%     LoadIdentityClut(w);
%     Screen('CloseAll');
%     rethrow(ME);
% end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Deal with key presses
function [...
    key,...
    fix_xpos,...
    fix_ypos,...
    wait_time,...
    choice_num,...
    x1,...
    y1,...
    x2,...
    y2...
    ] = key_check(...
    key,...
    fix_xpos,...
    fix_ypos,...
    wait_time,...
    choice_num,...
    x1,...
    y1,...
    x2,...
    y2,...
    sp...
    )

    if (~isempty(key))
        % We got an non-empty key, so act on it   
        
        switch (key.charCode)
            
            case 'GP:LeftJoystick'
                % move fixation point
                fix_ypos = fix_ypos + key.deltaY;
                fix_xpos = fix_xpos - key.deltaX;
                WaitSecs(wait_time+0.1);
                
            case 'GP:A'
                % submit choice
                if choice_num == 1
                    fprintf('\n Upper Left Corner: (%.1f, %.1f)', fix_xpos, fix_ypos);
                    x1 = fix_xpos;
                    y1 = fix_ypos;
                    choice_num = 2;
                elseif choice_num == 2
                    fprintf('\n Lower Right Corner: (%.1f, %.1f)', fix_xpos, fix_ypos);
                    x2 = fix_xpos;
                    y2 = fix_ypos;
                    choice_num = 3;
                end
                WaitSecs(wait_time+0.1);
                
            case 'GP:West'
                % move left
                fix_xpos = fix_xpos + sp.move_step;
                WaitSecs(wait_time);
            case 'GP:East'
                % move right
                fix_xpos = fix_xpos - sp.move_step;
                WaitSecs(wait_time);
            case 'GP:North'
                % move up
                fix_ypos = fix_ypos - sp.move_step;
                WaitSecs(wait_time);
            case 'GP:South'
                % move down
                fix_ypos = fix_ypos + sp.move_step;
                WaitSecs(wait_time);

        end % switch
    end %if

end % function key_check






end % function OzProjMap