function varargout = DIGIGUI(varargin)
% -------------------------------------------------------------------------
% Copyright (C) Reuben W. Nixon-Hill (formerly Reuben W. Hill)
%
% -------------------------------------------------------------------------
%                   -- DIGIGUI v1.2.1 for Matlab R2016b  --
% -------------------------------------------------------------------------
%
% For the Polhemus PATRIOT digitiser, attached to stylus pen with button.
%
% A list of points to digitise is imported from a text file, where each 
% point is on a new line.
%
% The baud rate is set via the variable "BaudRate" in 
% DIGIGUI_OutputFcn and has default value 115200.
%
% Points are digitised by pressing the stylus button.
%
% After getting 5 reference cardinal points 'Nasion','Inion','Ar','Al' and 
% 'Cz', an Atlas reference baby head, with these points marked, is mapped
% onto the graph display of points.
%
% Before the allignment of the head model, a coordinte transform is done: 
% 1: place the 'inion' at the origin
% 2: rotate the 'Al' into the y axis
% 3: rotate the 'Ar' into the xy plane about the new 'Inion'-'Al' y axis
% 4: Rotate about the 'Al'-'Ar' axis to bring the 'Nasion' into the xy
%    plane, thus alligning the inion and nasion.
% This coordinate transform is then applied to all measured points.
%
% A tab delimited list of points and their XYZ coords is outputted to 
% a file of the users choosing.
%
%
% MATLAB GUIDE Generated comments:
% DIGIGUI MATLAB code for DIGIGUI.fig
%      DIGIGUI, by itself, creates a new DIGIGUI or raises the existing
%      singleton*.
%
%      H = DIGIGUI returns the handle to a new DIGIGUI or the handle to
%      the existing singleton*.
%
%      DIGIGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DIGIGUI.M with the given input arguments.
%
%      DIGIGUI('Property','Value',...) creates a new DIGIGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before DIGIGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to DIGIGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help DIGIGUI

% Last Modified by GUIDE v2.5 18-Oct-2023 19:50:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DIGIGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @DIGIGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

function  r = FM_BYPASS_DEVICE_CHECK()
    r = true;
    return;

function  r = FM_IS_FASTRAK()
    r = true;
    return;

function  r = FM_FUNCION_AGREGADA()
    r = true;
    return;

% --- Executes just before DIGIGUI is made visible.
function DIGIGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to DIGIGUI (see VARARGIN)

% Choose default command line output for DIGIGUI
handles.output = hObject;

%-------------------Get the executable/.m directory--------------------

if isdeployed
    [status, result] = system('path');
    handles.currentDir = char(regexpi(result, 'Path=(.*?);', ...
        'tokens', 'once'));
end

%-------------------Get the default user location--------------------

if ispc
    handles.userDir = getenv('USERPROFILE');
else
    handles.userDir = getenv('HOME');
end

%--------------------define close request function----------------------
%the function "CloseFcn" that I define now runs when quitting the gui
set(gcf,'CloseRequestFcn',{@CloseFcn,handles});

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes DIGIGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);



% --- Outputs from this function are returned to the command line.
function varargout = DIGIGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------DISABLE HEAD ALIGNMENT BUTTON----------------------
if (~FM_BYPASS_DEVICE_CHECK())
    set(handles.HeadAlign,'Enable','off');
end
%-------------------CHECK FOR EXISTING SERIAL OBJECT----------------------

% Look for any existing serial port objects and warn user they may be
% deleted
button = 'OK';
if(~isempty(instrfindall))
    %show message box
    msgline1 = 'The Polhemus Patriot device will now be looked for on available COM ports.';
    msgline2 = 'Warning: existing serial port objects in MATLAB will be deleted if running as a MATLAB script.';
    msgline3 = 'Press OK to continue';
    msg = sprintf('%s\n\n%s\n\n%s',msgline1,msgline2,msgline3);
    disp(msgline2);
    button = questdlg(msg,'Initialising...','OK','Cancel','OK');
end

if(~strcmp(button,'OK'))
    %Quit the program
    disp('Now quitting by user request.');
    guidata(hObject, handles);
    CloseFcn(hObject,eventdata,handles);
    return;
end

%------------------------CREATE SERIAL OBJECT---------------------------

% Create serial object and set baud rate 
BaudRate = 115200;

% Find interface objects that are set to 'on' i.e. enabled...
InterfaceObj=findobj(handles.figure1,'Enable','on');
% ... and turn them off.
set(InterfaceObj,'Enable','off');
 
% find serial com port
if (FM_IS_FASTRAK())
    objFastrack = C_FASTRAK();
    [handles.COMport, handles.sensors] = objFastrack.iniciarFASTRAK();
else 
    [handles.COMport, handles.sensors] = FindPatriotSerial(BaudRate);
end

% Re-enable the interface objects.
set(InterfaceObj,'Enable','on');

if(handles.COMport ~= 0) %patriot found
    handles.serial = serial(handles.COMport,'BaudRate', BaudRate);
else
    if (~FM_IS_FASTRAK())
        %%%% FM MODIFICACION. Bypass de falta de dispositivo
        %%%% Para pruebas
        %-------------------QUIT & ERROR IF DEVICE NOT FOUND--------------------   
        str1 = 'Polhemus Patriot Device not found or communicated with successfully.';
        str2 = ['Check the device is on and its baud rate is set to '...
            sprintf('%i',BaudRate) ... 
            ' on both the hardware switches of the device and the settings of'...
            ' any USB link cable used.'];
        str3 = ['If running in MATLAB, try restarting MATLAB to scan for new'...
            ' serial devices.'];
        str4 = ['Also consider turning the device off and on. Take care to'...
            ' give the device time to reinitialise before trying again.'];
        errstr = sprintf('%s\n\n%s\n\n%s\n\n%s',str1,str2,str3,str4);
        % display error message
        uiwait(errordlg(errstr,'Polhemus Communications Initialisation Error'));
        % quit if com port not found
        guidata(hObject, handles);
        CloseFcn(hObject,eventdata,handles);
        return;
    end
end


%--------------------INITIALISE HANDLES VARIABLES--------------------
% Set the initial point count to 0. This is incremented before each
% measured head point until the last head point is measured.
handles.point_count = 0;

% this is true when opening save dialogues for example
handles.disable_measurements = false;

% this is true if the locations list has been edited.
handles.editedLocationsList = false;
% this is true if the atlas point names has been edited.
handles.editedAtlasPoints = false;

%--------------------HEADPOINTS TO DIGITISE INPUT-----------------------

try

    if (FM_BYPASS_DEVICE_CHECK())
        load(which('distribucion22OptodosFrontal.mat'),'locations');
    else
        load(which('savedLocationNames.mat'),'locations');
    end
catch
    uiwait(warndlg('Could not find previously used location list.',...
        'Location Warning','modal'));
    
    % Ask user to load a location list file. Note that the default deployed
    % location is handles.currentDir instead of handles.userDir since the
    % example locations list file can be found in the executable directory 
    % (handles.currentDir).
    if ~isdeployed
        [filename,pathname] = ... 
            uigetfile({'*.txt;*.dat;*.csv', ...
            'Text Files (*.txt) (*.dat) (*.csv)'} ...
            ,['Select Location List File - Each Measurement Point' ...
              ' should be on a New Line']);
    else
        [filename,pathname] = ... 
            uigetfile({'*.txt;*.dat;*.csv', ...
            'Text Files (*.txt) (*.dat) (*.csv)'} ...
            ,['Select Location List File - Each Measurement Point' ...
              ' should be on a New Line'],handles.currentDir);
    end

    if isequal(filename,0)
        disp('User selected Cancel')
        %Quit the gui
        guidata(hObject, handles);
        CloseFcn(hObject,eventdata,handles);
        return
    end

    disp(['User selected ', fullfile(pathname, filename)])

    % Open File
    FileID = fopen([pathname filename]);

    % locations is a local variable that holds location data in this
    % function
    locations = textscan(FileID,'%s','delimiter','\n');

    % append to list of reference points and convert to string array
    locations = ['Nasion';'Inion';'Ar';'Al';'Cz'; ... 
        locations{1,1}];

    % Close file
    fclose(FileID);

    % Save locations variable to be loaded next time
    if ~isdeployed
        save('savedLocationNames.mat','locations');
    else
        save(fullfile(ctfroot,'savedLocationNames.mat'),'locations');
    end
        
end

%load other data needed for headpoint plotting
handles.AtlasLandmarks = load('refpts_landmarks.mat');
handles.AtlasLandmarks = handles.AtlasLandmarks.pts;
handles.mesh = load('scalpSurfaceMesh.mat');
handles.mesh = handles.mesh.mesh;

if (~FM_BYPASS_DEVICE_CHECK())
    %error test the first serial port functions...
    try 
        %------------------------SERIAL CALLBACK SETUP---------------------
        %setup callback function to run when the polhemus system sends the 
        %number of bytes assosciated with one or two sensors. NB: the stated
        %number of bytes is generally position data.
        if(handles.sensors == 1)
            handles.serial.BytesAvailableFcnCount = 48; % 48 bytes for 1 sensor
        else
            handles.serial.BytesAvailableFcnCount = 96; % 96 bytes for 2 sensors
        end
        handles.serial.BytesAvailableFcnMode = 'byte';
        handles.serial.BytesAvailableFcn = {@ReadCoordsCallback,handles};
    
        %--------------------------OPEN SERIAL PORT------------------------
    
        fopen(handles.serial);
    
        %-------------------STYLUS POSITION MARKING SETUP------------------
        %The following ascii string causes the stylus button to send current
        %coords. Note: 13 is the ascii code for the required newline character
        if (~FM_IS_FASTRAK())
            string2write = ['L1,1' 13];
        else
            string2write = ['l1,1' 13];
        end

        fwrite(handles.serial,string2write);
        %fwrite is used because fprintf sometimes adds extra newline characters
    
        %set to output in cms
        if (~FM_IS_FASTRAK())
            string2write = ['U1' 13];
        else 
            string2write = 'u';
        end

        fwrite(handles.serial,string2write);
    
    
        %-----------------Display initial point to find on GUI-------------
    
        set(handles.infobox,'string',locations(1,1));
    
        % display locations on table in gui
        set(handles.coords_table,'Data',locations);
    
    %catch exception if error occurs
    catch serialException
        disp('COM PORT ERROR OCCURRED: Check COM Connection.')
        %run close function to close gui and delete serial port objects if
        %error occurs.
        CloseFcn(hObject,eventdata,handles);
        error(message('MATLAB:serial:fopen:opfailed', serialException.message))
    end
end

%-------------set graph axes labels and properties---------------------

xlabel(handles.coord_plot,'X');
ylabel(handles.coord_plot,'Y');
zlabel(handles.coord_plot,'Z');

% Update handles structure
guidata(hObject, handles);
  



% --- Executes on button press in HeadAlign.
function HeadAlign_Callback(hObject, eventdata, handles)
% hObject    handle to HeadAlign (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(handles.point_count >= 5)
    
    % extract the locations
   locations = get(handles.coords_table,'Data');

    % extract the landmark locations (the first five data points)...
    landmarks = locations(1:5,2:4);
    % ... and convert to ordinary array from cell array
    landmarks = cell2mat(landmarks);
    
    %get transformation matrix to new coord system
    [TransformMatrix,TransformVector] = GetCoordTransform(landmarks);
    %save tranformation
    handles.TransformMatrix = TransformMatrix;
    handles.TransformVector = TransformVector;
    
    % reset list of points to just show locations to find so transformed 
    % points can be plotted
    locations = get(handles.coords_table,'Data');
    
    hold on
    
    for k = 1:size(landmarks,1)
        %transform cardinal points
        landmarks(k,:) = landmarks(k,:) + TransformVector;
        landmarks(k,:) = landmarks(k,:)*TransformMatrix';

        %%% FM MODIFICACION. Agregado try
        try
            %remove old point from graph
            delete(handles.pointhandle(k));
        catch
        end

        %replot point
        handles.pointhandle(k) = plot3(landmarks(k,1), ...
                                       landmarks(k,2), ...
                                       landmarks(k,3), ...
                                       'm.', 'MarkerSize', 30, ...
                                       'Parent' , handles.coord_plot);
        
        if (FM_FUNCION_AGREGADA())
            for ix = 1:5
                signoX = sign(landmarks(k,1));
                signoY = sign(landmarks(k,2)); 
                factorX = 0.1;
                if signoX == 0 && signoY == 0
                    signoX = -1;
                    signoY = -1;
                    factorY = 2;
                else 
                    factorY = 0.1;
                end

                
                text(landmarks(k,1)*(1+factorX*signoX),landmarks(k,2)+(1+factorY*signoY),landmarks(k,3)*(1+0.05),locations{k,1},'Color','m');
            end
        end
        
        %replot axes...
        axis(handles.coord_plot,'equal');
        
        %update newly transformed cardinal point coords (converting back
        %to a cell array first)
        locations(k,2:4) = num2cell(landmarks(k,1:3));
                                              
    end


    if (FM_BYPASS_DEVICE_CHECK())
        landmarks2 = cell2mat(locations(6:end,2:4));
        
        for pointCount = 1:handles.point_count-5
            landmarks2(pointCount,:) = landmarks2(pointCount,:) + TransformVector;
            landmarks2(pointCount,:) = landmarks2(pointCount,:)*TransformMatrix';
    
            handles.pointhandle(pointCount) = plot3(landmarks2(pointCount,1), ...
                                                landmarks2(pointCount,2),landmarks2(pointCount,3), ... 
                                               'b.', 'MarkerSize', 30, ...
                                               'Parent',handles.coord_plot);
        
            text(landmarks2(pointCount,1),landmarks2(pointCount,2)+.3,landmarks2(pointCount,3)*(1-0.05),locations{pointCount + 5,1},'Color','b');
        end

                
  
        
        %%% Actualizar DATA (tabla) y locations (variable que alimenta a
        %%% data y que se guarda.
        for ix = 2:3 
            for iy = 6:size(locations,1) 
                locations{iy,ix} = landmarks2(iy-5,ix-1);
            end
        end
        set(handles.coords_table,'Data',locations);


    end
    
    hold off
    
    
    % Show newly transformed cardinal point coords on table
    set(handles.coords_table,'Data',locations);
    
    %find matrix (A) and vector (B) needed to map head to cardinal points
    %with affine transformation
    [A,B] = affinemap(handles.AtlasLandmarks,landmarks);

    mesh_trans = handles.mesh;
    mesh_trans.node = affine_trans_RJC(handles.mesh.node,A,B);

    %Then plot the transformed mesh as visual reference for further points...
    %note: this plots the head model
    hold on
    handles.headplot = trisurf(mesh_trans.face, mesh_trans.node(:,1), ...
                               mesh_trans.node(:,2),mesh_trans.node(:,3), ...
                               'FaceAlpha',0.6, ...
                               'FaceColor',[239/255 208/255 207/255], ... (skin tone rgb vals)
                               'EdgeColor','none', ...
                               'Parent',handles.coord_plot);
    
    % set lighting of head
    light;
    lighting gouraud;
    axis equal;
    hold off;
    
    
    % disable  headalign button
    set(hObject,'Enable','off');
    
    % Update handles structure
    guidata(hObject, handles);

end


%This function outputs a vector to transform inion to origin
%also outputs rotation transformation matrix to allign the head model to 
%intuitive coordinates. 
%To apply to row vector, the vector should be multiplied by the transpose
%with the vector on the left
function [Matrix,vector] = GetCoordTransform(landmarks)
%calculate lengths between vectors

%these are the untransformed reference points, defined here in case I want
%to use them
Nasion = landmarks(1,:);
Inion = landmarks(2,:);
Ar = landmarks(3,:);
Al = landmarks(4,:);
Cz = landmarks(5,:);

%------TRANSLATION-------

%translate inion to origion
vector = -Inion;

%translate Al
Al = Al + vector;

%------ROTATE AL TO Y AXIS-------

%calculate rotation to y axis
AlToYAxisRot = vrrotvec(Al,[0,1,0]);

%convert to rotation matrix
AlToYAxisMatrix = vrrotvec2mat(AlToYAxisRot);

%repmat
% Apply translation and rotation to points
for k = 1:5
    landmarks(k,:) = landmarks(k,:)+vector;
    landmarks(k,:) = landmarks(k,:)*AlToYAxisMatrix';
end

%------ROTATE AR TO XY PLANE ABOUT INION-AL AXIS-------

% find angle to rotate nasion into XY plane about the new y axis
[ArToXYRotAngle,~] = cart2pol(landmarks(3,1),landmarks(3,3));

%Find second rotation matrix
ArToXYMatrix = vrrotvec2mat([0,1,0,ArToXYRotAngle]);

% Apply second rotation to points
for k = 1:5
    landmarks(k,:) = landmarks(k,:)*ArToXYMatrix';
end

%------FINAL ROTATION ABOUT AL-AR AXIS TO ALLIGN INION AND NASION-------

%find angle of nasion to xy plane
[~,NasionToXYRotAngle,~] = cart2sph(landmarks(1,1),landmarks(1,2),landmarks(1,3));
%define vector to rotate around (the line joining AL and AR)
NasionRotVector = landmarks(4,:) - landmarks(3,:);
%find rotation matrix
NasionToXYRotMatrix = vrrotvec2mat([NasionRotVector, NasionToXYRotAngle]);

%------OUTPUT FINAL MATRIX-------
Matrix = NasionToXYRotMatrix*ArToXYMatrix*AlToYAxisMatrix;





function CloseFcn(source,event,handles)
%my user-defined close request function
%closes the serial port

handles = guidata(handles.figure1);

%close port only if not closed
if(isfield(handles,'COMport'))
    if(handles.COMport ~= 0)
        if( ~ strcmp(handles.serial.status, 'closed') )
            fclose(handles.serial);
        end
        delete(handles.serial);
    end
end

delete(gcf);


function ReadCoordsCallback(s,BytesAvailable,handles)

% Update handles structure to most current version
handles = guidata(handles.figure1);

%read the data on the serial port that triggered the callback
data_str=fgetl(s);

%read a second line if there are two sensors
if(handles.sensors == 2)
    data_str(2,:) = fgetl(s);
end



   
%don't run most of the callback if waiting to do alignment...
if(handles.point_count == 5 && ... 
        strcmp(get(handles.HeadAlign,'Enable'),'on') && ...
        handles.disable_measurements == false)
    % Warn user that points aren't collected until alignment done
    warndlg('Atlas points must be aligned before continuing.',...
        'Measurement Issue...','modal');
elseif(handles.disable_measurements == false)
    %increment the point count before measurement
    handles.point_count = handles.point_count + 1;
    
    if (FM_IS_FASTRAK() || FM_BYPASS_DEVICE_CHECK())
        data_num=str2num(strtrim(data_str(4:end)));
    else
        data_num=str2num(data_str);
    end

    % Format of data obtained for the current settings
    % 1 2 3 4 5 6 7
    % 1 Detector Number (should be 1 for 1 stylus)
    % 2 X position in cms
    % 3 Y position in cms
    % 4 Z position in cms
    % 5 Azimuth of stylus in degrees
    % 6 Elevation of stylus in degrees
    % 7 Roll of stylus degrees

    % extract coords
    if (FM_IS_FASTRAK())
        Coords = data_num(:,1:3);
    else
        Coords = data_num(:,2:4);
    end

    % if there are 2 sensors do vector subtraction to get position of
    % stylus sensor relative to second sensor
    if(handles.sensors == 2)
        Coords = Coords(1,:) - Coords(2,:);
    end

    % disable head alignment butten for first five points (they are the
    % landmark positions)
    if(handles.point_count < 5)
        if (~FM_BYPASS_DEVICE_CHECK())
            set(handles.HeadAlign,'Enable','off');
        end
    % enable head allign after 5 points...
    elseif(handles.point_count == 5)
        set(handles.HeadAlign,'Enable','on');
    % Do coord transform on points measured after landmark points
    else 
        Coords = Coords + handles.TransformVector;
        Coords = Coords*handles.TransformMatrix';
    end

    % Extract previous data from table
    data = get(handles.coords_table,'Data');
    
    % Check if table is currently full - if it is then adding a new point
    % will expand the table...
    if(handles.point_count > size(data,1))
        % ... so update the bool that tracks if location names have been 
        % edited. When the user saves their data they will therefore be
        % prompted to save the locations list too.
        handles.editedLocationsList = true;
    end
    
    % Update table with newly measured x y and z values
    data(handles.point_count,2:4) = num2cell(Coords);
    set(handles.coords_table,'Data',data);

    % update point to look for (unless at end of list as given by the
    % length of data - ie the number of headpoints)
    if( handles.point_count < size(data,1) )
        set(handles.infobox,'string', data(handles.point_count+1,1));
            % (Set to the next position on the table)
    else
        set(handles.infobox,'string','End of locations list reached');
    end  

    %add the measured point to the 3d graph
    hold(handles.coord_plot,'on');
    %save the handle of the point so it can be removed later...
    if(handles.point_count <= 5)
        handles.pointhandle(handles.point_count) = plot3(Coords(1), ...
                                            Coords(2),Coords(3), ...
                                            'm.', 'MarkerSize', 30, ...
                                            'Parent' , handles.coord_plot);
    else %Note: above marker points are plotted differently
        handles.pointhandle(handles.point_count) = plot3(Coords(1), ...
                                            Coords(2),Coords(3), ... 
                                           'b.', 'MarkerSize', 30, ...
                                           'Parent',handles.coord_plot);
    end

    if (FM_BYPASS_DEVICE_CHECK())
        for ix = 1:5
            signoX = sign(Coords(1));
            signoY = sign(Coords(2));
            text(Coords(1)*(1+0.1*signoX),Coords(2)*(1-0.1*signoY),Coords(3)*(1+0.05),data{ix,1},'Color','m');
        end
    end

    hold(handles.coord_plot,'off'); 
    %replot axes...
    axis(handles.coord_plot,'equal');
end

if (FM_IS_FASTRAK)
    %%% Limpiar buffer serial   
    flushinput(s);
    pause(0.1);

end

% Update handles structure
guidata(handles.figure1,handles);


% --- Executes on button press in remove_last_pt.
function remove_last_pt_Callback(hObject, eventdata, handles)
% hObject    handle to remove_last_pt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%don't delete points if alignment already done or at first point
if (handles.point_count ~= 0)
    if(handles.point_count ~= 5 || strcmp(get(handles.HeadAlign,'Enable'),'on') )

        data = get(handles.coords_table,'Data');
        
        % Set the last measured values of x, y and z to be empty cells
        data{handles.point_count,2} = []; % x
        data{handles.point_count,3} = []; % y
        data{handles.point_count,4} = []; % z
        
        set(handles.coords_table,'Data',data);

        % Remove point from graph...
        delete(handles.pointhandle(handles.point_count));
        % and replot axes.
        axis(handles.coord_plot,'equal');
        
        % Decrement point_count so next measurement is of the point which
        % has just been deleted
        handles.point_count = handles.point_count - 1;
        
        data = get(handles.coords_table,'Data');
        
        % update next point to look for string
        set(handles.infobox,'string', data(handles.point_count+1,1));
        
        % Disable align if now not enough points
        if(handles.point_count <= 5)
            if (~FM_BYPASS_DEVICE_CHECK())
                set(handles.HeadAlign,'Enable','off');
    
            end
        end
        % Update handles structure
        guidata(handles.figure1,handles);

    end
end



% --- Executes on button press in save.
function save_Callback(hObject, eventdata, handles)
% hObject    handle to save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% disable measurements
handles.disable_measurements = true;
guidata(hObject,handles);

% Find interface objects that are set to 'on' i.e. enabled...
InterfaceObj=findobj(handles.figure1,'Enable','on');
% ... and turn them off.
set(InterfaceObj,'Enable','off');

% Open a "Save As..." Dialogue with different saving options as shown.
% The filterIndex gives the index (1, 2 or 3) of the chosen save type.
if ~isdeployed
    [fileName,pathName,filterIndex] = ... 
        uiputfile({'*.csv;*.dat;*.txt', ... 
        'Comma-delimited text files (*.csv) (*.dat) (*.txt)'; ...
        ...
        '*.mat', ...
        'MAT-file (*.mat)'; ...
        ...
        '*.xls;*.xlsb;*.xlsm;*.xlsx', ...
        'Excel® spreadsheet files (*.xls) (*.xlsb) (*.xlsm) (*.xlsx)'; ...
        },'Save As...');
else
    [fileName,pathName,filterIndex] = ... 
        uiputfile({'*.csv;*.dat;*.txt', ... 
        'Comma-delimited text files (*.csv) (*.dat) (*.txt)'; ...
        ...
        '*.mat', ...
        'MAT-file (*.mat)'; ...
        ...
        '*.xls;*.xlsb;*.xlsm;*.xlsx', ...
        'Excel® spreadsheet files (*.xls) (*.xlsb) (*.xlsm) (*.xlsx)'; ...
        },'Save As...',handles.userDir);
end

% Re-enable the interface objects.
set(InterfaceObj,'Enable','on');

% re-enable measurements
handles.disable_measurements = false;
guidata(hObject,handles);

if(filterIndex ~= 0) % if == 0 then user selected "cancel" in "Save As"
    
    data = get(handles.coords_table,'Data');

    % check data cell array has same number of columns as there are column
    % names.
    if(size(data,2) < length(get(handles.coords_table,'ColumnName')))

        % dont save table if not enough data is available
        errordlg('Cannot save without recorded location data.', ... 
            'Save Error','modal');

        % exit function here
        guidata(hObject,handles);
        return;
    end
    
    % If the chosen save type is .mat then use a standard matlab save command
    if(filterIndex == 2)
        disp(['Data saving to ' pathName fileName]);
        dataOutput = get(handles.coords_table,'Data');
        save([pathName fileName],'dataOutput');
        disp('Data is stored in cell array "dataOutput"');
    
    % Otherwise create a table from the cell array and output that to file.    
    else
        % find any empty cells in Locations data
        emptyLocationNames = cellfun('isempty',data(:,1));
        buttonPressed = 'Yes';

        if(any(emptyLocationNames))
            % Warn the user if there are any location names missing...
            buttonPressed = questdlg({'Some location names are unspecified.';
                                      'Missing location names will be replaced by the symbol "-".';...
                                      'Would you like to continue?'},...
                                      'Warning','Yes','No','Yes'); 
        end

        %Only save data if user presses Yes or Yes has been set previously.
        if(strcmp(buttonPressed,'Yes'))

            disp(['Data saving to ' pathName fileName]);

            %Mark empty location names as '-'
            data(emptyLocationNames,1) = {'-'};       

            tableToOutput = cell2table(data,'VariableNames', ...
                                       get(handles.coords_table,'ColumnName'));
            % Note that writetable changes its output depending on the fileName
            % type.
            writetable(tableToOutput,[pathName fileName]);
        end
    end
    
    if(handles.editedLocationsList) % true if edited
        % check if user wants to save locations list too
        button = 'No';
        button = questdlg({['The locations list appears to have been'...
            ' edited or added to since it was last imported.'];...
            ['Would you also like to export your current '...
            'locations list?']},...
            'Export?','Yes','No','Yes');
        if(strcmp(button,'Yes'))
            % Call the export headpoints callback
            handles = guidata(handles.figure1);
            ExportHeadpoints_Callback(hObject, eventdata, handles);
        end
    end
    
end
guidata(hObject,handles);


% --- Executes when selected cell(s) is changed in coords_table.
function coords_table_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to coords_table (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)

if(isempty(eventdata.Indices))
    % delete 'selectedRow' field of 'handles' if the callback is triggered 
    % by deselection (eg by the removal or addition of a set of coordinates)
    handles = rmfield(handles,'selectedRow');
else
    % extract the row from where the user clicked on the table.
    handles.selectedRow = eventdata.Indices(:,1);
end
guidata(hObject,handles);



% --- Executes on button press in InsertRowPushbutton.
function InsertRowPushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to InsertRowPushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = get(handles.coords_table,'Data');

% See if the selectedRow variable exists within the handles struct 
% (doesn't if no selection performed before clicking or cell has been 
% deselected)
if(isfield(handles,'selectedRow'))
    if(handles.selectedRow(end) < 5)
        errordlg('Cannot insert or delete Atlas Points','Error','modal');
    else
        % insert above topmost selected row...
        row = handles.selectedRow(end);
        dataBelowSelectedRow = data(row+1:end,:);
        % add new row by adding a single rowed cell array
        data(row+1,:) = cell(1,size(data,2));
        % add back the data that was saved before by concatenating below where
        % the new row has been added.
        data = [data(1:row+1,:) ; dataBelowSelectedRow]; 
        
        % check if have added row within where measurement has already been 
        % made
        if(handles.selectedRow(end) < handles.point_count)
            % increment point count to account for 1 extra point
            handles.point_count = handles.point_count + 1;
        end
        
        % Locations list has now been edited so change bool.
        handles.editedLocationsList = true;
        
    end    
else
%    % insert empty row at the end
%    data{end+1,1} = [];
    
    % Tell user to select a row before inserting
    errordlg('Please select a row to insert below.','Insert Error','modal');   
end
% save the newly changed data to the table on the gui
set(handles.coords_table,'Data',data);
guidata(hObject,handles);

% --- Executes on button press in DeleteRowPushbutton.
function DeleteRowPushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to DeleteRowPushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = get(handles.coords_table,'Data');

% See if the selectedRow variable exists within the handles struct 
% (doesn't if no selection performed before clicking or cell has been 
% deselected)
if(isfield(handles,'selectedRow'))
    if(handles.selectedRow(1) <= 5)
        errordlg('Cannot insert or delete Atlas Points','Edit Error','modal');
    else
        % delete selected rows...
        data(handles.selectedRow,:) = [];
        
        % Locations list has now been edited so change bool.
        handles.editedLocationsList = true;
        
        % check if have deleted any rows where measurements have already 
        % been made
        if(any(handles.selectedRow <= handles.point_count))
            
            % find out how many of the selected rows are less than the
            % current point_count
            numToDecrement = nnz(handles.selectedRow <= handles.point_count);
            
            % decrement point count to account for number of fewer points
            handles.point_count = handles.point_count - numToDecrement;
            
            % Remove point from graph...
            delete(handles.pointhandle(handles.point_count));
            % and replot axes.
            axis(handles.coord_plot,'equal');
        end
    end    
else
    % Tell user to select a row before inserting
    errordlg('Please select a row to delete.','Delete Error','modal');    
end
% save the newly changed data to the table on the gui
set(handles.coords_table,'Data',data); 

guidata(hObject,handles);


% --- Executes on button press in ImportHeadpoints.
function ImportHeadpoints_Callback(hObject, eventdata, handles)
% hObject    handle to ImportHeadpoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
filename = [];
cargadoFicheroMat = false;
if (FM_BYPASS_DEVICE_CHECK()) %%%% ESTE CODIGO NO ESTÁ COMPLETO. NO SIRVE CON CSV.
    [filename,pathname] = ... 
    uigetfile({'*.mat;*.csv', ...
    'Ficheros admitidos Files (*.mat)(*.csv)'} ...
    ,['Fichero de datos a importar'],handles.userDir);
    
    [~,~,ext] = fileparts(filename);

    switch ext
        case '.mat'
            load(fullfile(pathname,filename),'locations');    
            handles.point_count = size(locations,1);
            cargadoFicheroMat = true;
        otherwise
            cargadoFicheroMat = false;
    end
end

if ~cargadoFicheroMat     
    % disable measurements
    handles.disable_measurements = true;
    guidata(hObject,handles);
    
    % Find interface objects that are set to 'on' i.e. enabled...
    InterfaceObj=findobj(handles.figure1,'Enable','on');
    % ... and turn them off.
    set(InterfaceObj,'Enable','off');
    
    %--------------------HEADPOINTS TO DIGITISE INPUT-----------------------
    if isempty(filename)
        if ~isdeployed
            [filename,pathname] = ... 
                uigetfile({'*.txt;*.dat;*.csv', ...
                'Text Files (*.txt) (*.dat) (*.csv)'} ...
                ,['Select Location List File - Each Measurement Point Should be'...
                ' on a New Line']);
        else
            [filename,pathname] = ... 
                uigetfile({'*.txt;*.dat;*.csv', ...
                'Text Files (*.txt) (*.dat) (*.csv)'} ...
                ,['Select Location List File - Each Measurement Point Should be'...
                ' on a New Line'],handles.userDir);
        end
    end
    % Re-enable the interface objects.
    set(InterfaceObj,'Enable','on');
    
    % re-enable measurements
    handles.disable_measurements = false;
    guidata(hObject,handles);
    
    % user selected cancel...
    if isequal(filename,0)
        return
    end
    
    % Warn user that this will reset all currently gathered data if any has
    % been collected.
    if(handles.point_count > 0)
        
        button = 'No';
    
        button = questdlg({'Warning! Any existing data will be lost.';...
            'Do you wish to continue?'},'Data Warning','Yes','No','No');
    
        % user selected cancel...
        if strcmp(button,'No')
            return
        end
        
    end
    
    disp(['User selected ', fullfile(pathname, filename)])
    
    % Open File
    FileID = fopen([pathname filename]);
    
    % locations is a local variable that holds location data in this
    % function
    locations = textscan(FileID,'%s','delimiter','\n');
    
    % append to list of reference points and convert to string array
    locations = ['Nasion';'Inion';'Ar';'Al';'Cz'; ... 
        locations{1,1}];
    
    % Close file
    fclose(FileID);
    
    % Save locations variable to be loaded next time
    if ~isdeployed
        save('savedLocationNames.mat','locations');
    else
        save(fullfile(ctfroot,'savedLocationNames.mat'),'locations');
    end
    % Reset points counter
    handles.point_count = 0;
end



% Display initial point to find on GUI
set(handles.infobox,'string',locations(1,1));

% display locations on table in gui
set(handles.coords_table,'Data',locations);

% if head align button has been enabled set to disabled.
if (FM_BYPASS_DEVICE_CHECK())
    set(handles.HeadAlign,'Enable','on');
else
    if(strcmp(get(handles.HeadAlign,'Enable'),'on'))
        set(handles.HeadAlign,'Enable','off');
    end
end

% clear previous measurements and headmap from plot...
cla(handles.coord_plot);
% and replot axes.
axis(handles.coord_plot,'equal');

% Locations list is now unedited (since it's just been imported) so reset
% both bools that deal with whether bits of the location list are edited.
handles.editedLocationsList = false;
handles.editedAtlasPoints = false;

guidata(hObject,handles);


% --- Executes on button press in ExportHeadpoints.
function ExportHeadpoints_Callback(hObject, eventdata, handles)
% hObject    handle to ExportHeadpoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Find interface objects that are set to 'on' i.e. enabled...

% disable measurements
handles.disable_measurements = true;
guidata(hObject,handles);

% Find interface objects that are set to 'on' i.e. enabled...
InterfaceObj=findobj(handles.figure1,'Enable','on');
% ... and turn them off.
set(InterfaceObj,'Enable','off');

% Display warning dialogue before uiputfile if the atlas points have been 
% editied...        
if(handles.editedAtlasPoints)
    uiwait(warndlg({['Note: Atlas points are NOT included in location'...
        ' list files.'];...
        ['Any atlas point renaming will NOT be reflected the'...
        ' exported file.']}...
    ,'Export Warning','modal'));
end

% Open an "Export" Dialogue
if ~isdeployed
    [fileName,pathName,filterIndex] = ... 
        uiputfile({'*.txt;*.dat;*.csv', ...
        'Text Files (*.txt) (*.dat) (*.csv)'} ...
        ,'Export Location List File ...');
else
    [fileName,pathName,filterIndex] = ... 
        uiputfile({'*.txt;*.dat;*.csv', ...
        'Text Files (*.txt) (*.dat) (*.csv)'} ...
        ,'Export Location List File ...',handles.userDir);
end

% Re-enable the interface objects.
set(InterfaceObj,'Enable','on');

% re-enable measurements
handles.disable_measurements = false;
guidata(hObject,handles);

% Otherwise create a table from the cell array and output that to file.
if(filterIndex ~= 0) % if == 0 then user selected "cancel" in save dialogue
    
    data = get(handles.coords_table,'Data');
 
    % error if outputting only atlas points 
    if(size(data,1) <= 5)
        errordlg({'Cannot export locations:';...
            'Only atlas point locations have been found.';...
            'Atlas points alone cannot be exported.'},...
            'Export Error','modal');
    else
       
        disp(['Locations saving to ' pathName fileName]);

        fileID = fopen([pathName fileName],'wt');

        %write from the 6th to the last data point
        for i = 5+1:size(data,1)
            fprintf(fileID,'%s\n',data{i,1});
        end

        fclose(fileID);
        clear fileID;
    
    end

end

guidata(hObject,handles);


% --- Executes on button press in measureThisRowButton.
function measureThisRowButton_Callback(hObject, eventdata, handles)
% hObject    handle to measureThisRowButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% See if the selectedRow variable exists within the handles struct 
% (doesn't if no selection performed before clicking or cell has been 
% deselected)
if(isfield(handles,'selectedRow'))
    
    if(length(handles.selectedRow) > 1)
        % Multiple rows/row elements selected
        errordlg({'Multiple rows or row elements have been selected.';...
            'Please select only a single cell.'},...
            'Selection Error','modal');  
    elseif(handles.selectedRow <= 5)
        % Atlas point selected
        errordlg(['Atlas Points can only be measured in order'...
            ' and cannot be changed after alignment.'],...
            'Selection Error','modal');  
    elseif(handles.point_count >= 5 && ...
            strcmp(get(handles.HeadAlign,'Enable'),'off')) 
            % (ie all atlas points collected and headalign clicked.)
        % Point selected successfully!
        
        % Set point_count such that the selected row will be measured
        handles.point_count = handles.selectedRow-1;
        
        % Update the "Point to Get" string
        data = get(handles.coords_table,'Data');
        set(handles.infobox,'string',...
                data(handles.selectedRow,1))
        
    else
        errordlg(['Please finish gathering atlas points then press '...
        '"Align Atlas Points" before selecting individual locations to ',...
        'measure the position of.'],'Selection Error','modal');
    end
else
    % No point selected
    
    % Tell user to select a row to measure at
    errordlg('Please select a row to gather location data.',...
        'Selection Error','modal');
end
guidata(hObject,handles);


% --- Executes when entered data in editable cell(s) in coords_table.
function coords_table_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to coords_table (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)

% Extract selected row
selectedRow = eventdata.Indices(:,1);

% Extract previous and new data (the eventdata fields are read only hence
% writing them to a new variable).
NewData = eventdata.NewData;
PreviousData = eventdata.PreviousData;

% warn when editing of rows less than 5 (atlas points)
if(selectedRow <= 5)
        
    % Check that user is happy to continue
    button = 'Yes';
    button = questdlg({['Warning! About to rename Atlas Point "' ...
        PreviousData, '" to "', NewData, '".']; ...
        '';...
        'Any changes will NOT be reflected in Exported Locations files';...
        '(exported using the "Export Locations..." button) but WILL be';... 
        ['reflected in saved data files (saved using the "Save Data'...
        ' As..." button.)'];...
        '';...
        'Do you wish to continue?'} ...
        ,'Rename Warning','Yes','No','No');
    
    % Set name to previous name prior to editing if user selects "no"
    if(strcmp(button,'No'))
        data = get(handles.coords_table,'Data');
        data{selectedRow,1} = PreviousData;
        set(handles.coords_table,'Data',data);
        NewData = PreviousData;
    else
        % Atlas points have been edited so update bool.flush
        handles.editedAtlasPoints = true;
    end
    
end
% if the previous and the new data are different set editedLocationsList to
% true.
if(~strcmp(PreviousData,NewData))
    handles.editedLocationsList = true;
end

guidata(hObject,handles);


% --- Executes on button press in restFastrak.
function restFastrak_Callback(hObject, eventdata, handles)
% hObject    handle to restFastrak (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (FM_IS_FASTRAK)
    fwrite(handles.serial,'W');
    pause(0.1);
    fwrite(handles.serial,['l1,1' 13]); %% Activar stylus, canal 1
    pause(0.1);
    fwrite(handles.serial,['A1,0,0,0,200,0,0,0,200,0' 13]); %% Activar stylus, canal 1
    pause(0.1);
    fwrite(handles.serial,['H1,0,0,1' 13]); %% Activar stylus, canal 1
    pause(0.1);
    fwrite(handles.serial,'c'); %% no continuo
    pause(0.1);
    fwrite(handles.serial,'u'); %% medidas métricas
    pause(0.1);
    fwrite(handles.serial,'F'); %% medidas ascii
    pause(0.1);
    fwrite(handles.serial,'D'); %% compensación de metal
    pause(0.1);
    fwrite(handles.serial,['e1,1' 13]); %% stylus point + track
    pause(0.1);
    fwrite(handles.serial,11); %% Ctrl K, guardar
    pause(0.1);
    fwrite(handles.serial,25); %% Ctrl Y, resetear
    pause(0.1);
end


% --- Executes on button press in pushbutton15.
function pushbutton15_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    fwrite(handles.serial,'P');
    pause(0.1);