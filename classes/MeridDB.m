classdef MeridDB < handle
%Class to connect to the MERID MySQL Database with a JDBC Connecter. It is
%mandatory to use the JDBC Connector, because the method 'runstoredprocedure'
%cannot be used with the ODBC Connector.
%
% 2019-05-13  Biebricher
%   * Function 'getMetaData()' changed to fetch timelog and pass it to existing ExperimentsMetaData class 
%   * Function 'getMetaData()' gives a warning when no meta data or time log is available
% 2019-06-12 Biebricher
%   * Function 'getExperimentData()' has been changed, so that even long-term
%       experiments (>150,000 lines) do not cause a memory overflow. The data
%       is retrieved in smaller packets of 50,000 rows and then merged into a table.
% 2019-08-12 Biebricher
%   * Function 'getExperiment()' output changed. Start and Endtime are part
%       of the output now.
% 2019-09-06 Biebricher
%   * Integrate handle class imports
% 2019-10-08 Biebricher
%   * Function 'getExperimentData()' error handlers for input parameters
%       added.
%   * Function 'getExperimentData()' new input parameter added
%       (forcedUpdate) and handed over to function 'prepareExperimentData()'.
%       Default value is 'false'.
%   * Function 'getExperimentData()' castl noRows as double.
% 2019-10-21 Biebricher
%   * All data will be catched from the data_raw database. This includes
%       that joining and synching the data will be done in matlab insted of
%       mysql. Multiple users can now connect to the database!
% 2019-10-22 Biebricher
%   * all variables in camel case
% 2019-10-28
%	* getExperimentData() added values for experiment start and end time
% 2019-10-31
%	* getExperimentData() corrected start and end time verification
% 2019-11-26
%	* catchFromDatabase() print experiment number while loading
    
    properties (Constant = true)
        %credentials and server data
        %db_table_inSync = 'data_inSync';    %databasename for synchron data
        dbTableRaw = 'data_raw';          %databasename for raw data
        dbVendor = 'MySQL';                %database vendor for example MySQL or Oracle
    end
    
    properties (SetAccess = immutable)
        %credentials
        dbUsername;        %username
        dbServer;          %server adress
        dbServerPort;     %server port        
    end
    
    properties (SetAccess = immutable, GetAccess = private)
        dbPasswort;        %passwort
    end
    
    properties (SetAccess = private)
        %credentials and server data
        dbConnectionRaw;
        
    end
    
    
    methods
        function obj = MeridDB(user, pass, ip, port)
        %Constructor to establish a connection to the database
        %Credentials will be checked and connection tested
           if (nargin == 4)
               
               %OUTSTANDING: Check if input is valid 
               obj.dbUsername = user;
               obj.dbPasswort = pass;
               obj.dbServer = ip;
               obj.dbServerPort = port; 
               
               %Try to connect to database
               try
                   obj.dbConnectionRaw = obj.openConnection(obj.dbTableRaw);
                   obj.closeConnection(obj.dbConnectionRaw);
                   
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
        
            connection = database(dbTable,obj.dbUsername, ...
                       obj.dbPasswort,'Vendor',obj.dbVendor, 'Server',obj.dbServer, ...
                       'PortNumber',obj.dbServerPort);
            
            %Check if the connection is established succesfull
            if (isopen(connection))
                disp([class(obj), ': ', 'Connection established to: ', dbTable]);
	                		
                query = ['USE ', dbTable];		
                exec(connection, query);
            else
                warning(connection.Message);
                error([class(obj), ': ', 'Connection cannot be established to: ', dbTable, '; (', connection.Message, ')']);
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
            obj.dbConnectionRaw = obj.openConnection(obj.dbTableRaw);
        
            try
                
                dbQuery = strcat('SELECT * FROM experiments');
                dbResult = select(obj.dbConnectionRaw,dbQuery);
                
                result = dbResult(:,{'experiment_no','short','time_start','time_end'});
                result.Properties.VariableNames = {'experimentNo' 'short' 'timeStart' 'timeEnd'}; %renaming columns in result table to match camelCase
                result.timeStart = datetime(result.timeStart,'InputFormat','yyyy-MM-dd HH:mm:ss.SSS');
                result.timeEnd = datetime(result.timeEnd,'InputFormat','yyyy-MM-dd HH:mm:ss.SSS');

            catch E
                fprintf('getExperiments without success: %s\n', E.message);
            end
            
            %Close connection
            obj.closeConnection(obj.dbConnectionRaw);
            
        end
        
        
        function result = experimentExists(obj,experimentNo)
        %Method to check if a experiment Exists in the MERID Database
            disp([class(obj), ': ', 'Check if experiment exists'])
        
            %Establish connection
            obj.dbConnectionRaw = obj.openConnection(obj.dbTableRaw);
            
            %Try to check if the experiment exists
            try
                dbQuery = strcat('SELECT * FROM experiments WHERE experiment_no= ',int2str(experimentNo));
                dbResult = select(obj.dbConnectionRaw,dbQuery);
                
                if (height(dbResult) == 1)
                    result = true;
                else
                    result = false;
                    warning([class(obj), ': ', 'Experiment does not exist']);
                end
            catch E
                throw (E);
            end
            
            %Close connection
            obj.closeConnection(obj.dbConnectionRaw);
        end
        

        function result = catchFromDatabase(obj, experimentNo, tableName, timeStart, timeEnd)
        %Function reading data from database
        
            %Open connection to database
            dbConnection = obj.openConnection(obj.dbTableRaw);

            %Experiments data have to be read in sequences of maximum
            %50000 rows. Otherwise the connection will be shut down by
            %matlab.
            selectionLimit = 50000; %maximum number of rows within one select query

            %Read the number of rows for the given experiment
			if ~isempty(timeStart) && ~isempty(timeEnd)
				dbQuery = ['SELECT COUNT(*) FROM `', tableName , '` WHERE `experiment_no`=',int2str(experimentNo), ' AND `time` BETWEEN ''', timeStart, ''' AND ''', timeEnd, ''''];
				dbResult = select(dbConnection,dbQuery);
			else
				dbQuery = strcat('SELECT COUNT(*) FROM `', tableName , '` WHERE `experiment_no`=',int2str(experimentNo));
				dbResult = select(dbConnection,dbQuery);
			end

            noRows = double(dbResult{1,1}); %total number of rows; cast as double for later calculation

            %Calculate the steps. Sometimes there is a problem when there
            %are too few lines. For this reason, you must check whether
            %the number of steps required is at least 1. Besides
            %noRows has to be casted as non integer. Otherwise the
            %division will be automatically round mathematically correct
            %and ceil() is useless.
            steps = ceil(noRows/selectionLimit);
            if (steps == 0)
                steps = 1;
            end

            disp([class(obj), ': ', '(#', int2str(experimentNo) ,') Fetching data from `', tableName, '` in ', int2str(steps), ' steps (', int2str(noRows) , ' rows).']);

            %Extract the data, taking into account the maximum number of rows
            for i = 0:steps-1
				if ~isempty(timeStart) && ~isempty(timeEnd)
					dbQuery = char(strcat('SELECT * FROM `', tableName, '` WHERE `experiment_no`= ',int2str(experimentNo), ' AND `time` BETWEEN ''', timeStart, ''' AND ''', timeEnd, ''' LIMIT ',{' '}, int2str(i*selectionLimit) ,',', int2str(selectionLimit)));
					dbResult = select(dbConnection,dbQuery);
				else
					dbQuery = char(strcat('SELECT * FROM `', tableName, '` WHERE `experiment_no`= ',int2str(experimentNo), ' LIMIT ',{' '}, int2str(i*selectionLimit) ,',', int2str(selectionLimit)));
					dbResult = select(dbConnection,dbQuery);
				end

                if (i == 0)
                    %Step 1: A data table is created
                    dataTable = dbResult;
                else
                    %Step X: The dataTable is extended by the new data
                    dataTable = union(dataTable, dbResult);
                end

                disp([class(obj), ': ', 'Fetching data - Step ', int2str(i+1), ' finished']);
            end
            
            %Close connection to database
            obj.closeConnection(dbConnection);
            
            result = dataTable;            
        end

        
        function result = joinDataTables(obj, dataPeekel, dataScale, dataPumps)
        %Recast data from table to timetable and join them without data loss
            
            syncable = 0;
        
            %Check if table is not empty. Otherwise a recast would fail
            if ~isempty(dataPeekel)
                dataPeekel.time = datetime(dataPeekel.time,'InputFormat','yyyy-MM-dd HH:mm:ss.SSS');
                dataPeekel = removevars(dataPeekel, 'experiment_no');
                dataPeekel = table2timetable(dataPeekel);
                syncable = syncable + 1;
            end
            
            if ~isempty(dataScale)
                dataScale.time = datetime(dataScale.time,'InputFormat','yyyy-MM-dd HH:mm:ss.SSS');
                dataScale = removevars(dataScale, 'experiment_no');
                dataScale = table2timetable(dataScale);
                syncable = syncable + 10;
            end
            
            if ~isempty(dataPumps)
                dataPumps.time = datetime(dataPumps.time,'InputFormat','yyyy-MM-dd HH:mm:ss.SSS');
                dataPumps = removevars(dataPumps, 'experiment_no');
                dataPumps = table2timetable(dataPumps);
                syncable = syncable + 100;
            end
            
            switch syncable
                case 1
                    dataTable = dataPeekel;
                case 10
                    dataTable = dataScale;
                case 11
                    dataTable = synchronize(dataPeekel, dataScale);
                case 100
                    dataTable = dataPumps;
                case 101
                    dataTable = synchronize(dataPeekel, dataPumps);
                case 110
                    dataTable = synchronize(dataScale, dataPumps);
                case 111
                    dataTable = synchronize(dataPeekel, dataScale, dataPumps);
                
               otherwise
                  error([class(obj), ': ', 'There are no datasets stored for this experiment!']);
            end
            
            result = dataTable;
                        
        end
        
        function result = getExperimentData(obj, experimentNo, timeStart, timeEnd)
        %Collect datasets from database, join and create object of
        %ExperimentsData-Class containing all datasets.
            import ExperimentsData.*
            
            %Check for correct input parameters     
            if nargin == 2
                timeStart = '';
				timeEnd = '';
            end
            
            if ~isnumeric(experimentNo)
                error([class(obj), ': ', 'The given experiment number is not numeric! Check if quotation marks used accidently.']);
            end
            
            %Check if the given experiment exists
            if (obj.experimentExists(experimentNo) == 0)
                error([class(obj), ': ','Selected experiment number (', int2str(experimentNo), ') does not exist']);
            else               
                dataPeekel = obj.catchFromDatabase(experimentNo, 'peekel_data', timeStart, timeEnd);
                dataScale = obj.catchFromDatabase(experimentNo, 'scale_fluid', timeStart, timeEnd);
                dataPumps = obj.catchFromDatabase(experimentNo, 'pumps_sigma2-3', timeStart, timeEnd);
                
                dataTable = obj.joinDataTables(dataPeekel, dataScale, dataPumps);
                
                data = ExperimentsData(experimentNo, dataTable);
                
                result = data;
            end
        end
        
        function result = getMetaData(obj, experimentNo)
        %Function to get experiment data from database
            import ExperimentsMetaData.*
            
            %Check if the given experiment exists
            if (obj.experimentExists(experimentNo) == 0)
                result = 0;
                warning([class(obj), ': ', 'No metadata for the experiment found']);
            else
                %Create metaData object
                metaData = ExperimentsMetaData(experimentNo);  
                
                %Open connection to database
                dbConnection = obj.openConnection(obj.dbTableRaw);
                
                try
                    dbQuery = strcat('SELECT * FROM experiments WHERE experiment_no = ',int2str(experimentNo));
                    dbResult = select(dbConnection,dbQuery);
                    
                    if (isempty(dbResult))
                        warning('No metadata found for experiment!')
                    else
                        dbResult.Properties.VariableNames = {'experimentNo' 'specimenId' 'description' 'comment' 'timeStart' 'timeEnd' 'short' 'pressureFluid' 'pressureConfining'}; %renaming columns in result table to match camelCase
                        metaData.setMetaDataAsTable(dbResult);
                    end
                    
                    
                catch E
                    warning('setting meta data without success: %s\n', E.message);
                end
                
                try
                    dbQuery = strcat('SELECT * FROM time_log WHERE experiment_no = ',int2str(experimentNo));
                    dbResult = select(dbConnection,dbQuery);
                    
                    if (isempty(dbResult))
                        warning('No time log found for experiment!')
                    else
                        dbResult.Properties.VariableNames = {'logId' 'experimentNo' 'retrospective' 'time' 'description'}; %renaming columns in result table to match camelCase
                        metaData.setTimeLogAsTable(dbResult);
                    end
                    
                    
                catch E
                    warning('setting time log without success: %s\n', E.message);
                end
                    
                result = metaData;

                %Close connection to database
                obj.closeConnection(dbConnection);
            end
        end
        
        function result = getSpecimenData(obj, experimentNo, specimenId)
        %Function to get specimen and rock data from database
            import ExperimentsSpecimenData.*
            
            %Open connection to database
            dbConnection = obj.openConnection(obj.dbTableRaw);

            %Create specimenData object
            specimenData = ExperimentsSpecimenData(experimentNo);  

            try
                dbProc = 'Fetch_Specimen_Data';
                dbResult = runstoredprocedure(dbConnection,dbProc,{specimenId});
                disp([class(obj), ': ', 'Preparing finisched']);

                dbQuery = strcat('SELECT * FROM joinspecimendata');
                dbResult = select(dbConnection,dbQuery);
                dbResult.Properties.VariableNames = {'specimenId' 'specimenName' 'height' 'diameter' 'massSat' 'massWet' 'massDry' 'rockName' 'description' 'densityWet' 'densitySat' 'densityDry' 'densityGrain' 'permCoeff' 'porosity' 'voidRatio' 'uniAxCompStrength' 'uniAxEModulus'}; %renaming columns in result table to match camelCase
                
                specimenData.setDataAsTable(dbResult);

            catch E
                warning('setting specimen data without success: %s\n', E.message);
            end

            result = specimenData;

            %Close connection to database
            obj.closeConnection(dbConnection);

        end
        
    end
end