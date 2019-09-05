classdef ExperimentsMetaData < handle
%Class to handle the meta data of MERID triaxial experiments. The
%experiment number has to be given while creating the class object.
%All metadata information like start and end time, comments or a
%description can be read directly from the class.
%Within the class the data will be saved in a table (metaDataTable). All
%depending variables like (description, short, etc.) are empty. They are some kind of
%proxy values to be able to work with the values as if they where saved in
%the variables.
%
%2019-05-13  Biebricher
%   * Added timeLog as variable
%   * Added setter 'setTimeLogAsTable()' for time log
%   * Added getter 'getTimeLog()' for time log
%   * Changed setter 'setMetaDataAsTable()' to recast start and end time to
%       Datetime format.
    
    properties (SetAccess = immutable)
        experimentNo; %Number of the experiment the metadata in this object contains to.
    end
    
    properties (SetAccess = private)
        description; %Proxyvariable for description in metadata. Data is only saved in metaDataTable.
        comment; %Proxyvariable for comments in metadata. Data is only saved in metaDataTable.
        time_start; %Proxyvariable for start time in metadata. Data is only saved in metaDataTable.
        time_end; %Proxyvariable for end time in metadata. Data is only saved in metaDataTable.
        short; %Proxyvariable for short name in metadata. Data is only saved in metaDataTable.
        specimenId; %Proxyvariable for specimen id in metadata. Data is only saved in metaDataTable.
        fluidPressure; %Proxyvariable for fluid pressure used in metadata. Data is only saved in metaDataTable.
        confiningPressure; %Proxyvariable for confining pressure used in metadata. Data is only saved in metaDataTable.
        metaDataTable; %Table containing all metadata from database
        timeLog; %Table containing the time log for the given experiment: experiment_no, retrospective, time, description
        
    end
    
    methods
        function obj = ExperimentsMetaData(experimentNo)
        %The experiment number (immutable) has to be set int the constructor and can
        %not be changed later.
            obj.experimentNo = experimentNo;
        end
        
        %SETTER
        function obj = setMetaDataAsTable(obj, metaDataTable)
        %Set all metadata for the experiment into the object.
        %Input parameter: table with metaData
            
            %Check if metadata fits to set experiment number
            if (metaDataTable.experiment_no(1) == obj.experimentNo)
                obj.metaDataTable = metaDataTable;
                
                obj.metaDataTable.Properties.VariableUnits{'pressure_fluid'} = 'kN/m²';
                obj.metaDataTable.Properties.VariableUnits{'pressure_confining'} = 'kN/m²';
                
                %Recasting datetime-String to real Datetime in Matlab
                obj.metaDataTable.time_start = datetime(obj.metaDataTable.time_start,'InputFormat','yyyy-MM-dd HH:mm:ss.S');
                obj.metaDataTable.time_end = datetime(obj.metaDataTable.time_end,'InputFormat','yyyy-MM-dd HH:mm:ss.S');
                
                disp([class(obj), ': ', 'Metadata set sucessfully']);
            else
               error('Given metadata do not fit to set experiment number');
            end
        end
        
        function obj = setTimeLogAsTable(obj, timeLogTable)
        %Set time log for the experiment into the object.
        %Input parameter: table with time log
            
            %Check if timelog fits to set experiment number
            if (timeLogTable.experiment_no(1) == obj.experimentNo)
                obj.timeLog = timeLogTable;
                
                %Recasting datetime-String to real Datetime in Matlab
                obj.timeLog.time = datetime(obj.timeLog.time,'InputFormat','yyyy-MM-dd HH:mm:ss.S');
                
                
                disp([class(obj), ': ', 'Time log set sucessfully']);
            else
               error('Given time log do not fit to set experiment number');
            end
        end
        
        function obj = setDescription(obj,description) 
        %Set a description for the experiment into the metadata. The
        %information will not be saved into the variable 'description'. It
        %is saved into the variable metaDataTable instead.
        %Input parameter: description as char
            obj.metaDataTable.description(1) = cellstr(description);
        end
        
        function obj = setComment(obj,comment) 
        %Set a comment for the experiment into the metadata. The
        %information will not be saved into the variable 'comment'. It
        %is saved into the variable metaDataTable instead.
        %Input parameter: comment as char
            obj.metaDataTable.comment(1) = cellstr(comment);
        end
        
        function obj = setTime_start(obj,time_start) 
        %Set a start time for the experiment into the metadata. The
        %information will not be saved into the variable 'time_start'. It
        %is saved into the variable metaDataTable instead.
        %Input parameter: start time as char
            obj.metaDataTable.time_start(1) = cellstr(time_start);
        end
        
        function obj = setTime_end(obj,time_end)
        %Set a end time for the experiment into the metadata. The
        %information will not be saved into the variable 'time_end'. It
        %is saved into the variable metaDataTable instead.
        %Input parameter: end time as char
            obj.metaDataTable.time_end(1) = cellstr(time_end);
        end
        
        function obj = setShort(obj,short) 
        %Set a short name for the experiment into the metadata. The
        %information will not be saved into the variable 'short'. It
        %is saved into the variable metaDataTable instead.
        %Input parameter: short name as char
            obj.metaDataTable.short(1) = cellstr(short);
        end
        
        %GETTER
        function experimentNo = get.experimentNo(obj) 
            experimentNo = obj.experimentNo;
        end
        
        function description = get.description(obj) 
            description = obj.metaDataTable.description{1};
        end
        
        function comment = get.comment(obj) 
            comment = obj.metaDataTable.comment{1};
        end
        
        function time_start = get.time_start(obj) 
            time_start = obj.metaDataTable.time_start(1);
        end
        
        function time_end = get.time_end(obj) 
            time_end = obj.metaDataTable.time_end(1);
        end
        
        function short = get.short(obj) 
            short = obj.metaDataTable.short{1};
        end
        
        function specimen_id = get.specimenId(obj) 
            specimen_id = obj.metaDataTable.specimen_id;
        end
        
        function pressure_fluid = get.fluidPressure(obj) 
            pressure_fluid = obj.metaDataTable.pressure_fluid;
        end
        
        function pressure_confining = get.confiningPressure(obj) 
            pressure_confining = obj.metaDataTable.pressure_confining;
        end
        
        function timeLog = get.timeLog(obj) 
            %Getter for the experiments time log.
            %Column 'retrospective' contains a boolean value that tells you whether the 
            %information was recorded during or after the experiment.
            timeLog = obj.timeLog;
           
        end
        
        
        
    end
end