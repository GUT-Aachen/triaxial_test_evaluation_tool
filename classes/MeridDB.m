classdef MeridDB < handle
    %Class to connect to the MERID MySQL Database with a JDBC Connector. It
    %is mandatory to use the JDBC Connector, as the method 
    %'runstoredprocedure' cannot be used with the ODBC Connector.
	% All datetime values querried from the mysql database are UTC!
    
    properties (Constant = true)
        dbTableRaw = 'data_raw';  %databasename for raw data
        dbVendor = 'MySQL';  %database vendor for example MySQL or Oracle
    end
    
    properties (SetAccess = immutable)
        dbUsername;  %username
        dbServer;  %server adress
        dbServerPort;  %server port        
    end
    
    properties (SetAccess = immutable, GetAccess = private)
        dbPasswort;  %passwort
    end
    
    properties (SetAccess = private)
        dbConnectionRaw;
        
    end
    
    
    methods
        function obj = MeridDB(user, pass, ip, port)
        %Constructor to establish a connection to the database.
        %Credentials will be checked and connection tested.
           if (nargin == 4)
               
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
               error('%s: number of arguments wrong', class(obj));
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
                if contains(connection.Message, 'No suitable driver found for jdbc')
                    error('%s: JDBC Driver not found. Is the JDBC driver available in javapath? Check with ', ...
                        ' ''javaclasspath''. If JDBC Driver not availabe add via ', ...
                        '''javaaddpath(/your_folder/driver_file_name.jar)''. \n(%s)', ...
                        class(obj), connection.Message);
                elseif contains(connection.Message, 'Communications link failure')
                    warning(connection.Message);
                    error('%s: Connection error. A connection to the database server can not established. Check ', ...
                        'if a connection to the server (%s:%d) can be established. \n(%s)', ...
                        class(obj), obj.dbServer, obj.dbServerPort, connection.Message);
                elseif contains(connection.Message, 'time zone value')
					warning(connection.Message);
                    error('%s: Time zone error. Check mysql server time zone and do not use MEZ/MESZ. \n(%s)', ...
                        class(obj), connection.Message);
                else
                    warning(connection.Message);
                    error('%s: connection cannot be established to "%s" \n(%s)', class(obj), dbTable, connection.Message);
                end
            end
        end
        
        function closeConnection(obj, dbConnection)
        %Method to close a particular database connection
            close(dbConnection);
            if (isopen(dbConnection))
                error('%s: connection cannot be closed.', class(obj));
            else
                disp([class(obj), ': ', 'connection closed.']);
            end
        end
        
        %%
        function result = getExperiments(obj)           
        %Method to get information about all existing experiments in the
        %database.
            obj.dbConnectionRaw = obj.openConnection(obj.dbTableRaw);
        
            try
                
                dbQuery = strcat("SELECT `experiment_no`, `short`, `time_start`, `time_end`, `assistant`, `pretest`, `testRigId` FROM data_raw.experiments");
                dbResult = select(obj.dbConnectionRaw,dbQuery);
                
                result = dbResult;
                result.Properties.VariableNames = {'experimentNo' 'short' 'timeStart' 'timeEnd','assistant','preTest','testRigId'}; %renaming columns in result table to match camelCase
                result.timeStart = datetime(result.timeStart,'InputFormat','yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', 'UTC');
                result.timeEnd = datetime(result.timeEnd,'InputFormat','yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', 'UTC');

            catch E
                warning('%s: getExperiments without success \n(%s)', class(obj), E.message);
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
                dbQuery = strcat('SELECT experiment_no FROM experiments WHERE experiment_no= ',int2str(experimentNo));
                dbResult = select(obj.dbConnectionRaw,dbQuery);
                
                if (height(dbResult) == 1)
                    result = true;
                else
                    result = false;
                    warning('%s: Experiment does not exist', class(obj));
                end
            catch E
                throw (E);
            end
            
            %Close connection
            obj.closeConnection(obj.dbConnectionRaw);
        end
        

        function result = catchFromDatabase(obj, experimentNo, tableName)
        %Function reading data from database
        
            %Open connection to database
            dbConnection = obj.openConnection(obj.dbTableRaw);

            %Experiments data have to be read in sequences of maximum
            %50000 rows. Otherwise the connection will be shut down by
            %matlab.
            selectionLimit = 50000; %maximum number of rows within one select query

            %Read the number of rows for the given experiment
			dbQuery = strcat('SELECT COUNT(experiment_no) FROM `', tableName , '` WHERE `experiment_no`=',int2str(experimentNo));
			dbResult = select(dbConnection,dbQuery);

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

				dbQuery = char(strcat('SELECT * FROM `', tableName, '` WHERE `experiment_no`= ',int2str(experimentNo), ' LIMIT ',{' '}, int2str(i*selectionLimit) ,',', int2str(selectionLimit)));
				dbResult = select(dbConnection,dbQuery);


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
                dataPeekel.time = datetime(dataPeekel.time,'InputFormat','yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', 'UTC');
                dataPeekel = removevars(dataPeekel, 'experiment_no');
                dataPeekel = table2timetable(dataPeekel);
                syncable = syncable + 1;
            end
            
            if ~isempty(dataScale)
                dataScale.time = datetime(dataScale.time,'InputFormat','yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', 'UTC');
                dataScale = removevars(dataScale, 'experiment_no');
                dataScale = table2timetable(dataScale);
                syncable = syncable + 10;
            end
            
            if ~isempty(dataPumps)
                dataPumps.time = datetime(dataPumps.time,'InputFormat','yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', 'UTC');
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
                  error('%s: there are no datasets stored for this experiment!', class(obj));
            end
            
            result = dataTable;
                        
        end
        
        function result = getExperimentData(obj, experimentNo)
        %Collect datasets from database, join and create object of
        %ExperimentsData-Class containing all datasets.
            import ExperimentsData.*
            
            if ~isnumeric(experimentNo)
                error('%s: given experiment number is not numeric! Check if quotation marks used accidently.', class(obj));
            end
            
            %Check if the given experiment exists
            if (obj.experimentExists(experimentNo) == 0)
                error('%s: selected experiment number (%d) does not exist', class(obj), experimentNo);
            else               
                dataPeekel = obj.catchFromDatabase(experimentNo, 'peekel_data');
                dataScale = obj.catchFromDatabase(experimentNo, 'scale_fluid');
                dataPumps = obj.catchFromDatabase(experimentNo, 'pumps_sigma2-3');
                
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
                warning('%s: No metadata for the experiment found', class(obj));
            else
                %Create metaData object
                metaData = ExperimentsMetaData(experimentNo);  
                
                %Open connection to database
                dbConnection = obj.openConnection(obj.dbTableRaw);
                
				try
                    dbQuery = strcat("SELECT `experiment_no`, `specimen_id`, `testRigId`, `description`, `comment`, `time_start`, `time_end`, `short`, `pressure_fluid`, `pressure_confining`, `assistant`, `pretest`, `const_head_diff`, `init_perm_coeff` FROM experiments WHERE experiment_no = ",int2str(experimentNo));
                    dbResult = select(dbConnection,dbQuery);
                    
					%Set timezone of metadata
					dbResult.time_start = datetime(dbResult.time_start, 'TimeZone', 'UTC');
					dbResult.time_end = datetime(dbResult.time_end, 'TimeZone', 'UTC');
					
                    if (isempty(dbResult))
                        warning('no metadata found for experiment!')
                    else
                        dbResult.Properties.VariableNames = {'experimentNo' 'specimenId' 'testRigId' 'description' 'comment' 'timeStart' 'timeEnd' 'short' 'pressureFluid' 'pressureConfining' 'assistant' 'pretest' 'constHeadDiff' 'initPermCoeff'}; %renaming columns in result table to match camelCase
                        metaData.setMetaDataAsTable(dbResult);
                    end
                    
                    
                catch E
                    warning('setting meta data without success: %s\n', E.message);
				end
				
				try
                    dbQuery = strcat('SELECT `experiment_no`, `retrospective`, `time`, `description` FROM time_log WHERE experiment_no = ',int2str(experimentNo));
                    dbResult = select(dbConnection,dbQuery);
                    
                    if (isempty(dbResult))
                        warning('No time log found for experiment!')
                    else
                        dbResult.Properties.VariableNames = {'experimentNo' 'retrospective' 'time' 'description'}; %renaming columns in result table to match camelCase
						dbResult.time = datetime(dbResult.time, 'TimeZone', 'UTC');
                        metaData.setTimeLogAsTable(dbResult);
                    end
                    
                    
                catch E
                    warning('setting time log without success: %s\n', E.message);
				end
				
				
				try
					testRigId = metaData.metaDataTable.testRigId;
					dbQuery = strcat('SELECT `id`, `name`, `description`, `diameter_max`, `height_max`, `axial_cylinder_kg_max`, `axial_cylinder_p_max`, `confining_p_max` FROM testrig WHERE id = ',int2str(testRigId));
					dbResult = select(dbConnection,dbQuery);

					if (isempty(dbResult))
						warning('No test rig found for experiment!')
					else
						dbResult.Properties.VariableNames = {'id' 'name' 'description' 'diameterMax' 'heightMax' 'axialCylinderKgMax' 'axialCylinderPMax' 'confiningPMax'}; %renaming columns in result table to match camelCase
						metaData.setTestRigDataAsTable(dbResult);
					end


				catch E
					warning('setting test rig data without success: %s\n', E.message);
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
                dbResult = runstoredprocedure(dbConnection,dbProc,{specimenId});  % use inner join functions of MySQL to join specimen and rock information
                disp([class(obj), ': ', 'Preparing finisched']);

                dbQuery = strcat('SELECT `specimen_id`, `specimen_name`, `height`, `diameter`, `mass_sat`, `mass_wet`, `mass_dry`, `rock_name`, `description`, `density_wet`, `density_sat`, `density_dry`, `density_grain`, `perm_coeff`, `porosity`, `void_ratio`, `uniAx_comp_strength`, `uniAx_emodulus` FROM joinspecimendata');
                dbResult = select(dbConnection,dbQuery);
				
				if height(dbResult) > 0
					dbResult.Properties.VariableNames = {'specimenId' 'specimenName' 'height' 'diameter' 'massSat' 'massWet' 'massDry' 'rockName' 'description' 'densityWet' 'densitySat' 'densityDry' 'densityGrain' 'permCoeff' 'porosity' 'voidRatio' 'uniAxCompStrength' 'uniAxEModulus'}; %renaming columns in result table to match camelCase
				else
					error('database result for "%s" is empty. No specimen with id %d found.', dbQuery, specimenId);
				end
                
                specimenData.setDataAsTable(dbResult);

            catch E
                error('%s: setting specimen data without success: %s\n', class(obj), E.message);
            end

            result = specimenData;

            %Close connection to database
            obj.closeConnection(dbConnection);

		end
        
    end
end