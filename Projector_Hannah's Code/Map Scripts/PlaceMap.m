%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function which allows subject to map between SLO- and projector-
% coordinate spaces. Subject moves square of preset size to frame the
% raster.

function maps = PlaceMap


    % clear; close all;
    Screen('Preference', 'SkipSyncTests', 1);
    Screen('Preference','VisualDebugLevel', 0);

    update_display = 1; % display will update on startup
    

    
    %% Collect user input
    commandwindow;
    
    %% Get a window ready
    which_screen = max(Screen('Screens'));
    
    [w,rect] = Screen('OpenWindow',which_screen,[0 0 0]);
    
    LoadIdentityClut(w); %load in a linear LUT

    [screen_width, screen_height] = Screen('WindowSize',w);
   
    % Instantiate a gamePad object
    gamePad = GamePad();

    
    %% Default spatial parameters
    sp.move_step = 1;
    sp.field_size = 1.1; %size of the raster in degrees
    pix_per_degree = 50; % projector pixels per degree
    frame_dim = round(pix_per_degree*sp.field_size);
    % load previous location as starting position
    try
        temp = load('registration.mat','maps');
        frame_xpos = temp.maps(1) - frame_dim/2;
        frame_ypos = temp.maps(2) + frame_dim/2;
    catch
        frame_xpos = round(screen_width/2);
        frame_ypos = round(screen_height/2);
    end
    sp.fix_width = 1;
    sp.fix_length = 4;
    draw_color =[150 150 150];
    
    %% Default temporal parameters
    wait_time = 0.3; %delay time between key checks, in seconds
    
    %% Default color parameters
    sp.bg_rgb = [0, 0, 0]; % background RGB
    bg_rgb = sp.bg_rgb;
    
    %% Other defaults
    choice_num = 1;
    x1 = 0;
    y1 = 0;
    x2 = 0;
    y2 = 0;

    %% Begin task
    all_done = false;
    while all_done == false


        
        move_on = false;
        while move_on == false
            
            if update_display == 1

                    % Draw background (it's a big rectangle)
                    Screen('FillRect',w,bg_rgb); %background
                    
                    % Draw frame with lines extending past corners
                    % (so that it can be seen outside of the raster)
                    extend = 30;
                    x_coords = [frame_xpos - frame_dim/2 - extend, frame_xpos + frame_dim/2 + extend,...
                        frame_xpos - frame_dim/2 - extend, frame_xpos + frame_dim/2 + extend,...
                        frame_xpos - frame_dim/2, frame_xpos - frame_dim/2,...
                        frame_xpos + frame_dim/2, frame_xpos + frame_dim/2];
                        
                    y_coords = [frame_ypos - frame_dim/2, frame_ypos - frame_dim/2,...
                        frame_ypos + frame_dim/2, frame_ypos + frame_dim/2,...
                        frame_ypos - frame_dim/2 - extend, frame_ypos + frame_dim/2 + extend,...
                        frame_ypos - frame_dim/2 - extend, frame_ypos + frame_dim/2 + extend];
                    coords = [x_coords; y_coords];
                    Screen('DrawLines', w, coords, 1, draw_color);
                                
                    % Draw fixation cross
                    x_coords = [frame_xpos-sp.fix_length, frame_xpos+sp.fix_length,...
                        frame_xpos, frame_xpos];
                    y_coords = [frame_ypos, frame_ypos, frame_ypos-sp.fix_length,...
                        frame_ypos+sp.fix_length];
                    coords = [x_coords; y_coords];
                    Screen('DrawLines', w, coords, sp.fix_width, draw_color); 

                    % "Flip" the offscreen graphics buffer to the front so it's
                    % visible to the subject.
                    Screen('Flip',w);

                
            end
            
            %% Check for key presses
            key = gamePad.getKeyEvent();
                if choice_num == 2
                
                    
                    LoadIdentityClut(w);
                    Screen('CloseAll');
                    x1 = frame_xpos + frame_dim/2;
                    y1 = frame_ypos - frame_dim/2;
                    x2 = frame_xpos - frame_dim/2;
                    y2 = frame_ypos + frame_dim/2;
                    maps = [x1, y1, x2, y2];
                    % save maps to a file for use from session-to-session
                    save('registration.mat','maps');
                    
                    return;
                    
                else
                    
                    % deal with key presses
                    [...
                        key,...
                        frame_xpos,...
                        frame_ypos,...
                        wait_time,...
                        choice_num,...
                        x1,...
                        y1,...
                        x2,...
                        y2...
                        ] = key_check(...
                        key,...
                        frame_xpos,...
                        frame_ypos,...
                        wait_time,...
                        choice_num,...
                        x1,...
                        y1,...
                        x2,...
                        y2,...
                        sp...
                        ); 

                end
        end
            
            
    end
    


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Deal with key presses
function [...
    key,...
    frame_xpos,...
    frame_ypos,...
    wait_time,...
    choice_num,...
    x1,...
    y1,...
    x2,...
    y2...
    ] = key_check(...
    key,...
    frame_xpos,...
    frame_ypos,...
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
                frame_ypos = frame_ypos + key.deltaY;
                frame_xpos = frame_xpos - key.deltaX;
                WaitSecs(wait_time);
                
            case 'GP:A'
                % submit choice
                if choice_num == 1
                    fprintf('\n Center of Raster: (%.1f, %.1f)', frame_xpos, frame_ypos);
                    choice_num = 2;
                end
                WaitSecs(wait_time);
                
            case 'GP:West'
                % move left
                frame_xpos = frame_xpos + sp.move_step;
                WaitSecs(wait_time);
            case 'GP:East'
                % move right
                frame_xpos = frame_xpos - sp.move_step;
                WaitSecs(wait_time);
            case 'GP:North'
                % move up
                frame_ypos = frame_ypos - sp.move_step;
                WaitSecs(wait_time);
            case 'GP:South'
                % move down
                frame_ypos = frame_ypos + sp.move_step;
                WaitSecs(wait_time);

        end % switch
    end %if

end % function key_check






end % function OzProjMap