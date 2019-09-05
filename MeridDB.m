classdef MeridDB < handle
%Class to connect to the MERID MySQL Database with a JDBC Connecter. It is
%mandatory to use the JDBC Connector, because the method 'runstoredprocedure'
%cannot be used with the ODBC Connector.
%
%2019-05-13  Biebricher
%   * Function 'getMetaData()' changed to fetch timelog and pass it to existing ExperimentsMetaData class 
%   * Function 'getMetaData()' gives a warning when no meta data or time log is available
%2019-06-12 Biebricher
%   * Function 'getExperimentData()' has been changed, so that even long-term
%       experiments (>150,000 lines) do not cause a memory overflow. The data
%       is retrieved in smaller packets of 50,000 rows and then merged into a table.
%2019-08-12 Biebricher
%   * Function 'getExperiment()' output changed. Start and Endtime are part
%       of the output now.
    
    properties (Constant = true)
        %credentials and server data
        db_table_inSync = 'data_inSync';    %databasename for synchron data
        db_table_raw = 'data_raw';          %databasename for raw data
        db_vendor = 'MySQL';                %database vendor for example MySQL or Oracle
    end
    
    properties (SetAccess = immutable)
        %credentials
        db_username;        %username
        db_server;          %server adress
        db_server_port;     %server port        
    end
    
    properties (SetAccess = immutable, GetAccess = private)
        db_passwort;        %passwort
    end
    
    properties (SetAccess = private)
        %credentials and server data
        db_connection_inSync;
        db_connection_raw;
        
    end
    
    
    methods
        function obj = MeridDB(user, pass, ip, port)
        %Constructor to establish a connection to the database
        %Credentials will be checked and connection tested
           if (nargin == 4)
               
               %OUTSTANDING: Check if input is valid 
               obj.db_username = user;
               obj.db_passwort = pass;
               obj.db_server = ip;
               obj.db_server_port = port; 
               
               %Try to connect to database
               try
                   obj.db_connection_raw = obj.openConnection(obj.db_table_raw);
                   obj.closeConnection(obj.db_connection_raw);
                   obj.db_connection_inSync = obj.openConnection(obj.db_table_inSync);
                   obj.closeConnection(obj.db_connection_inSync);
               catch E
                   throw(E);
               end

           else
               error([class(obj), ': ', 'Number of arguments wrong']);
           end
        end
        
        %%
        function connection = openConnection(obj, dbTable)
        %Method to open a particular database connection and check if
        %the connection could be established. Otherwise a error is thrown
        
            connection = database(dbTable,obj.db_username, ...
                       obj.db_passwort,'Vendor',obj.db_vendor, 'Server',obj.db_server, ...
                       'PortNumber',obj.db_server_port);
            
            %Check if the connection is established succesfull
            if (isopen(connection))
                disp([class(obj), ': ', 'Connection established to: ', dbTable]);
	                		
                query = ['USE ', dbTable];		
                exec(connection, query);
            else
                warning(connection.Message);
                error([class(obj), ': ', 'Connection cannot be established to: ', dbTable]);
            end
        end
        
        function closeConnection(obj, dbConnection)
        %Method to close a particular database connection
            close(dbConnection);
            if (isopen(dbConnection))
                error([class(obj), ': ', 'Connection cannot be closed.']);
            else
                disp([class(obj), ': ', 'Connection closed.']);
            end
        end
        
        %%
        function result = getExperiments(obj)
        %Method to get information about all existing experiments in the
        %database.
            obj.db_connection_raw = obj.openConnection(obj.db_table_raw);
        
            try
                
                db_query = strcat('SELECT * FROM experiments');
                db_result = select(obj.db_connection_raw,db_query);
                
                
                result = db_result(:,{'experiment_no','short','time_start','time_end'});
                result.time_start = datetime(result.time_start,'InputFormat','yyyy-MM-dd HH:mm:ss.S');
                result.time_end = datetime(result.time_end,'InputFormat','yyyy-MM-dd HH:mm:ss.S');

            catch E
                fprintf('getExperiments without success: %s\n', E.message);
            end
            
            %Close connection
            obj.closeConnection(obj.db_connection_raw);
            
        end
        
        
        function result = experimentExists(obj,experimentNo)
        %Method to check if a experiment Exists in the MERID Database
            disp([class(obj), ': ', 'Check if experiment exists'])
        
            %Establish connection
            obj.db_connection_raw = obj.openConnection(obj.db_table_raw);
            
            %Try to check if the experiment exists
            try
                db_query = strcat('SELECT * FROM experiments WHERE experiment_no= ',int2str(experimentNo));
                db_result = select(obj.db_connection_raw,db_query);
                
                if (height(db_result) == 1)
                    result = true;
                else
                    result = false;
                    warning([class(obj), ': ', 'Experiment does not exist']);
                end
            catch E
                throw (E);
            end
            
            %Close connection
            obj.closeConnection(obj.db_connection_raw);
        end
        
        function result = prepareExperimentData(obj, experimentNo, forced)
        %Method to call the procedure in the database to fetch the data
        %from all data-tables. This procedure takes time and just needs to
        %be done if the experimentNo changes or it is forced.
            
            if (nargin == 2)
                forced = false;
            end
            
            %Open the connection to the database
            db_connection = obj.openConnection(obj.db_table_inSync);
            
            %A database comparison must only be carried out if an update
            %is not forced anyway.
            if (forced == false)
                %Check if the procedure needs to be called. Is the experimentNo
                %in the first element in the data table the same?
                
                db_query = strcat('SELECT * FROM fetch_Data_Table WHERE experiment_no= ',int2str(experimentNo),' LIMIT 3');
                db_result = select(db_connection,db_query);
                
                %When the result is empty, we need an update
                if (height(db_result) > 0)
                    updateNeeded = false;
                else
                    updateNeeded = true;
                end
            end
            
            %Start the procedure if needd
            if (forced || updateNeeded)
                disp([class(obj), ': ', 'Preparing to start to fetch all kind of data into one table']);

                if (forced) disp([class(obj), ': ', 'Database update is forced']); end

                db_proc = 'Fetch_Data_InnerJoin';
                db_result = runstoredprocedure(db_connection,db_proc,{experimentNo});
                disp([class(obj), ': ', 'Preparing finisched']);
                result = db_result;
            else
                disp([class(obj), ': ', 'No update of the database is needed.']);
            end
            
            %Close the connection anyway
            obj.closeConnection(db_connection);
        end
        
        function result = getExperimentData(obj, experimentNo)
        %Function to get experiment data from database
            
            %Check if the given experiment exists
            if (obj.experimentExists(experimentNo) == 0)
                result = 0;
            else               
                %Preparing of the dataset takes time and needs to be done
                %everytime the experiment number changes
                obj.prepareExperimentData(experimentNo, false);
                
                %Open connection to database
                db_connection = obj.openConnection(obj.db_table_inSync);
                
                %Read the number of rows for the given experiment
                db_query = strcat('SELECT COUNT(*) FROM fetch_Data_Table WHERE experiment_no= ',int2str(experimentNo));
                db_result = select(db_connection,db_query);
                
                select_limit = 50000; %maximum number of rows within one select query
                no_rows = db_result{1,1}; %total number of rows
                
                %Calculate the steps. Sometimes there is a problem when there
                %are too few lines. For this reason, you must check whether
                %the number of steps required is at least 1. 
                steps = ceil(no_rows/select_limit);
                if (steps == 0)
                    steps = 1;
                end
                
                disp([class(obj), ': ', 'Fetching experiment data in ', int2str(steps), ' steps (', int2str(no_rows) , ' rows).']);
                
                %Extract the data, taking into account the maximum number of rows
                for i = 0:steps-1
                    
                    db_query = char(strcat('SELECT * FROM fetch_Data_Table WHERE experiment_no= ',int2str(experimentNo), ' LIMIT ',{' '}, int2str(i*select_limit) ,',', int2str(select_limit)));
                    db_result = select(db_connection,db_query);
                    
                    if (i == 0)
                        %Step 1: A data table is created
                        data_table = db_result;
                    else
                        %Step X: The data_table is extended by the new data
                        data_table = union(data_table, db_result);
                    end
                    
                    disp([class(obj), ': ', 'Fetching experiment data - Step ', int2str(i+1), ' finished']);
                end
                
                data = ExperimentsData(experimentNo, data_table);
                
                result = data;
                %Close connection to database
                obj.closeConnection(db_connection);
            end
        end
        
        function result = getMetaData(obj, experimentNo)
        %Function to get experiment data from database
            
            %Check if the given experiment exists
            if (obj.experimentExists(experimentNo) == 0)
                result = 0;
                warning([class(obj), ': ', 'No metadata for the experiment found']);
            else
                %Create metaData object
                metaData = ExperimentsMetaData(experimentNo);  
                
                %Open connection to database
                db_connection = obj.openConnection(obj.db_table_raw);
                
                try
                    db_query = strcat('SELECT * FROM experiments WHERE experiment_no = ',int2str(experimentNo));
                    db_result = select(db_connection,db_query);
                    
                    if (isempty(db_result))
                        warning('No metadata found for experiment!')
                    else
                        metaData.setMetaDataAsTable(db_result);
                    end
                    
                    
                catch E
                    warning('setting meta data without success: %s\n', E.message);
                end
                
                try
                    db_query = strcat('SELECT * FROM time_log WHERE experiment_no = ',int2str(experimentNo));
                    db_result = select(db_connection,db_query);
                    
                    if (isempty(db_result))
                        warning('No time log found for experiment!')
                    else
                        metaData.setTimeLogAsTable(db_result);
                    end
                    
                    
                catch E
                    warning('setting time log without success: %s\n', E.message);
                end
                    
                result = metaData;

                %Close connection to database
                obj.closeConnection(db_connection);
            end
        end
        
        function result = getSpecimenData(obj, experimentNo, specimenId)
        %Function to get specimen and rock data from database
            
        %Open connection to database
        db_connection = obj.openConnection(obj.db_table_raw);

        %Create specimenData object
        specimenData = ExperimentsSpecimenData(experimentNo);  

        try
            db_proc = 'Fetch_Specimen_Data';
            db_result = runstoredprocedure(db_connection,db_proc,{specimenId});
            disp([class(obj), ': ', 'Preparing finisched']);

            db_query = strcat('SELECT * FROM joinspecimendata');
            db_result = select(db_connection,db_query);

            specimenData.setDataAsTable(db_result);
            
        catch E
            warning('setting specimen data without success: %s\n', E.message);
        end

        result = specimenData;

        %Close connection to database
        obj.closeConnection(db_connection);

        end
        
    end
end