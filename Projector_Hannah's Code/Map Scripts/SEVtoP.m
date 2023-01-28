% Convert from SEV to Projector coordinates.
% Projector space has the origin in the top right corner. The subject will
% have performed a calibration by aligning two fixation points with the top
% left and bottom right corners of the raster. (The raster is contained
% fully within the projector display.) These coordinates are (x1, y1) and
% (x2, y2) which are contained in maps = [x1 y1 x2 y2].
% SEV space has the origin at the center of the SLO raster with Cartesian
% xy-conventions.
function xy_P = SEVtoP(xy_SEV, fov_width, fov_height, maps)

% extract from maps
x1 = maps(1);
y1 = maps(2);
x2 = maps(3);
y2 = maps(4); 

map_width = x1-x2;
map_height = y2-y1;

xc = x2 + map_width/2; % center of the raster map in projector space
yc = y1 + map_height/2; % center of the raster map in projector space

% append to xy_SEV
xy_SEV = [xy_SEV; 1];

% construct homogeneous matrix
M = [-map_width/fov_width, 0, xc;...
    0, -map_height/fov_height, yc;...
    0, 0, 1];

% apply to xy_SEV
xy_P = M*xy_SEV;

% only return x and y
xy_P = [xy_P(1); xy_P(2)];


end % function