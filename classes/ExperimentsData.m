classdef ExperimentsData < handle
    %Class for handling experiment data from an MERID triaxial experiment. The class
    %is able to get a database dump directly from the MySQL database and
    %handle it.
    %IMPORTANT:
    %This class is directly dependent on the structure of the database. The 
    %names of the table columns are accessed so that they must not be
    %changed. If the names are changed the function organizeTableData() has
    %to be adapted with new names.
    %
    %It is possible to get specific experiment data instead of the whole
    %table.
    %
    % 2019-05-16 Biebricher
    %   * Bugfix getFlowData(): Changed fluid_t to fluid_out_t
    % 2019-05-14 Biebricher
    %   * Creator changed to work with fluid temperature in and out seperate
    %   * Changed getAllTemperatures(): Missing data will be filled up by a
    %       linear interpolation between two neighbors.
    % 2019-05-13 Biebricher
    %   * Changed name from 'getChamberPumpData' to 'getBassinPumpData'
    %   * Added some more unit information to datatable
    % 2019-06-28 Hiestermann
    %   *Added Calculation Table 
    %   *Added getPermeability function
    %   *Added Analytics Table
    % 2019-08-09 Biebricher
    %   *Changed all table-variables to timetable-variables
    %   *Include checks for all input parameters for all functions
    %   *Adding some aditional comments in code
    %   *Deprecated function getCalculationData
    %   *Adding function waterDensity(T), extracted from getCalculationData
    %   *Refactoring getPermeability
    %   *Refactoring getAnalytics to getAnalyticsDataForGUI
    %   *Added function organizeTableData(data) to check the consistence of
    %       the given data stream and add additional information like units
    %       and description. Data conversion from table to timetable
    % 2019-08-15 Hiestermann
    %   *Added deformation deviation to getAnalyticsDataforGUI
    % 2019-08-30 Hiestermann
    %   *Added mean filter to getAllPressureRelative; window of 20 for
    %   fluid pressure, window of 50 for confining pressure and pressure of hydraulic
    %   cylinder 
    % 2019-09-03 Hiestermann
    %   *Added median filter to getAllTemperature; 
    %   *Added median filter to getDeformationRelative
    % 2019-09-06 Biebricher
    %   *Added filterTableData() as a function to filter the data once
    %       globaly. All other function adapted.
    %   *Added showDebugPlotSingle() as function to plot all datasets
    %       modified by filterTableData()
    %   *Deprecated function getConfiningPressureRelative(). Use
    %       getConfiningPressure().
    %   *Fixed issues with VariableUnits and VariableDescription
    %   *Changed access to 'private' for organizeTableData() and
    %       filterTableData().
    %   *Changed access to private for dataTables
    % 2019-09-09 Biebricher
    %   * getPermeability() added check if diameter or length are NaN
    % 2019-09-30 Biebricher
    %   * getPermeability() add debug mode: output all parameters
    %   * getPermeability() prohibit negative weight differences and
    %                       replace by 0
    
    properties (SetAccess = immutable)%, GetAccess = private)
        originalData; %Dataset as timetable
        filteredData; %Filtered dataset as timetable
    end
    
    properties (SetAccess = immutable)
        experimentNo; %Experiment number of the data
        rows;         %Number of entries on originalData/filteredData
    end
    
    methods (Access = private)
        function dataTable = organizeTableData(obj, data)
        %This function is used to have specific names for each column, even
        %if the names in the database and therefore in the incomming data
        %stream changed. Additionaly the units, names and descriptions of
        %the columns will be added.
        
            %Check if all columns are present and add units and description
            try
                dataTable = table(data.time);
                dataTable.Properties.VariableNames = {'time'};
                dataTable.Properties.VariableDescriptions{'time'} = 'Datetime in the format: yyyy-MM-dd HH:mm:ss.S';
                
                dataTable.timestamp = data.timestamp;
                dataTable.Properties.VariableUnits{'timestamp'} = 's';
                dataTable.Properties.VariableDescriptions{'timestamp'} = 'Unix timestamp';

                dataTable.room_t = data.room_t;
                dataTable.Properties.VariableUnits{'room_t'} = '°C';
                dataTable.Properties.VariableDescriptions{'room_t'} = 'Ambient air temperature';

                dataTable.room_p_abs = data.room_p_abs;
                dataTable.Properties.VariableUnits{'room_p_abs'} = 'bar';
                dataTable.Properties.VariableDescriptions {'room_p_abs'} = 'Atmospheric pressure';

                dataTable.fluid_in_t = data.fluid_in_t;
                dataTable.Properties.VariableUnits{'fluid_in_t'} = '°C';
                dataTable.Properties.VariableDescriptions {'fluid_in_t'} = 'Temperature of the fluid before flowing the specimen.';

                dataTable.fluid_out_t = data.fluid_out_t;
                dataTable.Properties.VariableUnits{'fluid_out_t'} = '°C';
                dataTable.Properties.VariableDescriptions {'fluid_out_t'} = 'Temperature of the fluid after flowing through, meassured on the scale.';

                dataTable.fluid_p_abs = data.fluid_p_abs;
                dataTable.Properties.VariableUnits{'fluid_p_abs'} = 'bar';
                dataTable.Properties.VariableDescriptions {'fluid_p_abs'} = 'Inflow pressure specimen (absolute value)';

                dataTable.fluid_p_rel = data.fluid_p_rel;
                dataTable.Properties.VariableUnits{'fluid_p_rel'} = 'bar';
                dataTable.Properties.VariableDescriptions {'fluid_p_rel'} = 'Inflow pressure specimen (relative value)';

                dataTable.hydrCylinder_p_abs = data.hydrCylinder_p_abs;
                dataTable.Properties.VariableUnits{'hydrCylinder_p_abs'} = 'bar';
                dataTable.Properties.VariableDescriptions {'hydrCylinder_p_abs'} = 'Operating pressure of the hydraulic cylinder (absolue value)';

                dataTable.hydrCylinder_p_rel = data.hydrCylinder_p_rel;
                dataTable.Properties.VariableUnits{'hydrCylinder_p_rel'} = 'bar';
                dataTable.Properties.VariableDescriptions {'hydrCylinder_p_rel'} = 'Operating pressure of the hydraulic cylinder (relative value)';

                dataTable.sigma2_3_p_abs = data.sigma2_3_p_abs;
                dataTable.Properties.VariableUnits{'sigma2_3_p_abs'} = 'bar';
                dataTable.Properties.VariableDescriptions {'sigma2_3_p_abs'} = 'Confining pressure in the bassin. Meassured at the inflow pipe (absolute value)';

                dataTable.sigma2_3_p_rel = data.sigma2_3_p_rel;
                dataTable.Properties.VariableUnits{'sigma2_3_p_rel'} = 'bar';
                dataTable.Properties.VariableDescriptions {'sigma2_3_p_rel'} = 'Confining pressure in the bassin. Meassured at the inflow pipe (relative value)';

                dataTable.deformation_1_U = data.deformation_1_U;
                dataTable.Properties.VariableUnits{'deformation_1_U'} = 'V';
                dataTable.Properties.VariableDescriptions {'deformation_1_U'} = 'Voltage of the first deformation sensor';

                dataTable.deformation_1_s_abs = data.deformation_1_s_abs;
                dataTable.Properties.VariableUnits{'deformation_1_s_abs'} = 'mm';
                dataTable.Properties.VariableDescriptions {'deformation_1_s_abs'} = 'Absolute deformation derived from the voltage';

                dataTable.deformation_1_s_rel = data.deformation_1_s_rel;
                dataTable.Properties.VariableUnits{'deformation_1_s_rel'} = 'mm';
                dataTable.Properties.VariableDescriptions {'deformation_1_s_rel'} = 'Relative deformation, zeroed at the beginning of the experiment';

                dataTable.deformation_1_s_taravalue = data.deformation_1_s_taravalue;
                dataTable.Properties.VariableUnits{'deformation_1_s_taravalue'} = 'mm';
                dataTable.Properties.VariableDescriptions {'deformation_1_s_taravalue'} = 'Difference between absolute and relative derformation meassurement';

                dataTable.deformation_2_U = data.deformation_2_U;
                dataTable.Properties.VariableUnits{'deformation_2_U'} = 'V';
                dataTable.Properties.VariableDescriptions {'deformation_2_U'} = 'Voltage of the second deformation sensor';

                dataTable.deformation_2_s_abs = data.deformation_2_s_abs;
                dataTable.Properties.VariableUnits{'deformation_2_s_abs'} = 'mm';
                dataTable.Properties.VariableDescriptions {'deformation_2_s_abs'} = 'Absolute deformation derived from the voltage';

                dataTable.deformation_2_s_rel = data.deformation_2_s_rel;
                dataTable.Properties.VariableUnits{'deformation_2_s_rel'} = 'mm';
                dataTable.Properties.VariableDescriptions {'deformation_2_s_rel'} = 'Relative deformation, zeroed at the beginning of the experiment';

                dataTable.deformation_2_s_taravalue = data.deformation_2_s_taravalue;
                dataTable.Properties.VariableUnits{'deformation_2_s_taravalue'} = 'mm';
                dataTable.Properties.VariableDescriptions {'deformation_2_s_taravalue'} = 'Difference between absolute and relative derformation meassurement';

                dataTable.pump_1_V = data.pump_1_V;
                dataTable.Properties.VariableUnits{'pump_1_V'} = 'ml';
                dataTable.Properties.VariableDescriptions {'pump_1_V'} = 'Liquid present in the pump';

                dataTable.pump_1_p = data.pump_1_p;
                dataTable.Properties.VariableUnits{'pump_1_p'} = 'bar';
                dataTable.Properties.VariableDescriptions {'pump_1_p'} = 'Pressure measured internally in the pump (relative value)';

                dataTable.pump_2_V = data.pump_2_V;
                dataTable.Properties.VariableUnits{'pump_2_V'} = 'ml';
                dataTable.Properties.VariableDescriptions {'pump_2_V'} = 'Liquid present in the pump';

                dataTable.pump_2_p = data.pump_2_p;
                dataTable.Properties.VariableUnits{'pump_2_p'} = 'bar';
                dataTable.Properties.VariableDescriptions {'pump_2_p'} = 'Pressure measured internally in the pump (relative value)';

                dataTable.pump_3_V = data.pump_3_V;
                dataTable.Properties.VariableUnits{'pump_3_V'} = 'ml';
                dataTable.Properties.VariableDescriptions {'pump_3_V'} = 'Liquid present in the pump';

                dataTable.pump_3_p = data.pump_3_p;
                dataTable.Properties.VariableUnits{'pump_3_p'} = 'bar';
                dataTable.Properties.VariableDescriptions {'pump_3_p'} = 'Pressure measured internally in the pump (relative value)';

                dataTable.weight = data.weight;    
                dataTable.Properties.VariableUnits{'weight'} = 'kg';
                dataTable.Properties.VariableDescriptions {'weight'} = 'Weight of the water meassured on the scale';
            catch E
                error([class(obj), ' - ', 'The given dataset is missing a column or properties can not be added. Please control the given data to be complete.']);
            end
            
            %Recast time-String to datetime, calculate time dependend
            %variables like runtime and convert to timetable
            try
                %Convert time-column in datetime-variable
                dataTable.time = datetime(dataTable.time,'InputFormat','yyyy-MM-dd HH:mm:ss.S');
               
                %Calculate runtime
                dataTable.runtime = seconds(data{:,2}-data{1:1,2}); %working with timestamp
                dataTable.Properties.VariableUnits{'runtime'} = 's';
                dataTable.Properties.VariableDescriptions{'runtime'} = 'Runtime in seconds since experiment start';
                
                %Convert table to timetable
                dataTable = table2timetable(dataTable);
                
                %Set variable continuity for synchronizing data
                %time is unset, should not be filled
                %pressure and temperature are continious
                %deformation related meassurements are stepwise
                %volume in pumps is stepwise
                %weight on scale is stepwise
                dataTable.Properties.VariableContinuity = {'unset', 'continuous', 'continuous', 'continuous', 'continuous', 'continuous', 'continuous', 'continuous', 'continuous', 'continuous', 'continuous', 'step', 'step', 'step',  'step',  'step',  'step',  'step',  'step',  'step', 'continuous', 'step', 'continuous', 'step', 'continuous', 'step', 'continuous'};
                
            catch E
                error([class(obj), ' - ', 'Can not convert data to timetable and/or claculate time difference']);
            end
            
        end
        
        
        function dataTable = filterTableData(obj, data)
        %This function is used to filter most of the data
            
            %Prepare input for return, changed in data like filtering are
            %going to update the data in dataTable
            dataTable = data;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %PRESSURE
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            try
                dat = data.sigma2_3_p_abs;
                dat = fillmissing(dat, 'nearest');
                dat = lowpass(dat, 0.01);
                dataTable.sigma2_3_p_abs = round(dat, 2);
                
                dat = data.sigma2_3_p_rel;
                dat = fillmissing(dat, 'nearest');
                dat = lowpass(dat, 0.01);
                dataTable.sigma2_3_p_rel = round(dat, 2);

            catch
                warning([class(obj), ' - ', 'Error while filtering sigma2_3_p_abs/sigma2_3_p_rel']);
            end
            
            try
                dat = data.room_p_abs;
                dat = fillmissing(dat, 'nearest');
                dat = movmedian(dat, 50);
                dataTable.room_p_abs = round(dat, 3);

            catch
                warning([class(obj), ' - ', 'Error while filtering room_p_abs']);
            end
            
            try
                dat = data.hydrCylinder_p_abs;
                dat = fillmissing(dat, 'nearest');
                dat = lowpass(dat, 0.05);
                dataTable.hydrCylinder_p_abs = round(dat, 1);
                
                dat = data.hydrCylinder_p_rel;
                dat = fillmissing(dat, 'nearest');
                dat = lowpass(dat, 0.05);
                dataTable.hydrCylinder_p_rel = round(dat, 1);

            catch
                warning([class(obj), ' - ', 'Error while filtering hydrCylinder_p_abs/hydrCylinder_p_rel']);
            end
            
            try
                dat = data.fluid_p_abs;
                dat = fillmissing(dat, 'nearest');
                dat =  movmedian(dat, 50);
                dataTable.fluid_p_abs = round(dat, 3);
                
                dat = data.fluid_p_rel;
                dat = fillmissing(dat, 'nearest');
                dat = movmedian(dat, 50);
                dataTable.fluid_p_rel = round(dat, 3);

            catch
                warning([class(obj), ' - ', 'Error while filtering fluid_p_abs/fluid_p_rel']);
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %TEMPERATURES
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %PT100 Temperatures as filtered by movmedian
            try
                dat = data.fluid_in_t;
                dat = filloutliers(dat, 'nearest', 'movmedian', 180);
                dat = fillmissing(dat, 'nearest');
                dat = movmedian(dat, 600);
                dataTable.fluid_in_t = round(dat, 1);

            catch
                warning([class(obj), ' - ', 'Error while filtering fluid_in_t']);
            end
            
            try
                dat = data.fluid_out_t;
                dat = filloutliers(dat, 'nearest', 'movmedian', 180);
                dat = fillmissing(dat, 'nearest');
                dat = movmedian(dat, 600);
                dataTable.fluid_out_t = round(dat, 1);

            catch
                warning([class(obj), ' - ', 'Error while filtering fluid_out_t']);
            end
            
            try
                dat = data.room_t;
                dat = filloutliers(dat, 'nearest', 'movmedian', 180);
                dat = fillmissing(dat, 'nearest');
                dat = movmedian(dat, 600);
                dataTable.room_t = round(dat, 1);

            catch
                warning([class(obj), ' - ', 'Error while filtering room_t']);
            end
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %DEFORMATION
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Filtering of deformation must be used carefully, as we have a
            %changed deformation meassurement system
            try
                dat = movmedian(data.deformation_1_s_abs, 30);
                dataTable.deformation_1_s_abs = round(dat, 2);
                
                dataTable.deformation_1_s_rel = round(dat - min(dat), 2);
            catch
                warning([class(obj), ' - ', 'Error while filtering deformation_1_s_abs/deformation_1_s_rel']);
            end
            
            try
                dat = movmedian(data.deformation_2_s_abs, 30);
                dataTable.deformation_2_s_abs = round(dat, 2);   
                
                dataTable.deformation_2_s_rel = round(dat - min(dat), 2);
            catch
                warning([class(obj), ' - ', 'Error while filtering deformation_2_s_abs/deformation_2_s_rel']);
            end
            
        end
        
        function dataTable = createTable(obj)
            dataTable = obj.filteredData(:,{'runtime'}); 
        end
        
    end
    
    methods
        function obj = ExperimentsData(experimentNo, data)
            %Input parameters are the experiment number and a table
            %containing all experiments data. The handed over data is a
            %class of table, will be converted into a timetable and saved
            %in this object.
            
            %Inputdata consistence checks
                %Check if there are two variables handed over
                if (nargin ~= 2)
                    error('Not enough input arguments. Two input parameters have to be handed over: experimentNo as Integer and data as timetable.')
                end

                %Check if the variable experimentNo is numeric
                if ~isnumeric(experimentNo)
                    error(['Input "experimentNo" must consider a numeric-variable. Handed variable is class of: ',class(experimentNo)])
                end

                %Check if the variable data is a table
                if ~istable(data)
                    error(['Input "data" must consider a timetable-variable. Handed variable is class of: ',class(data)])
                end

                %Check if the data table is empty
                if height(data) == 0
                    error('Data table for the experiment is empty')
                end
            
            %Organize all data in the table: adding units and desciptions
            %Convert from table to timetable
            data = obj.organizeTableData(data);
            
            %Filter all data
            obj.filteredData = obj.filterTableData(data);
            
            %Saving variables in actual object
            obj.experimentNo = experimentNo; 
            obj.originalData = data;
            obj.rows = height(data);
            
        end
        
        function fig = showDebugPlotSingle(obj, columnName)
        %Function to plot a single rows data as original and filtered data
        %When columnName parameter is 'all' then all filtered columns will
        %be shown in a seperate figure. Otherwise the given columnName will
        %be shown.
            try
                if (columnName == "all")

                    fig = [];
                    variables=obj.originalData.Properties.VariableNames;

                    for k=1:length(variables)

                        x1 = obj.originalData.runtime;
                        x2 = x1;

                        y1 = obj.originalData.(k);
                        y2 = obj.filteredData.(k);

                        y1 = fillmissing(y1, 'nearest');
                        y2 = fillmissing(y2, 'nearest');

                        if (not(isequal(y1, y2)) && not(sum(isnan(y1)) == length(y1)))

                            fig_temp = figure;
                            plot(x1,y1,':' ,x2,y2);
                            title(variables(k), 'Interpreter', 'none');
                            legend('Original', 'Filtered');

                            fig = [fig, fig_temp];
                        end
                    end

                else

                    x1 = obj.originalData.runtime;
                    x2 = x1;

                    y1 = obj.originalData.(columnName);
                    y2 = obj.filteredData.(columnName);

                    fig = figure;
                    plot(x1,y1,x2,y2);
                    title(columnName, 'Interpreter', 'none');
                    legend('Original', 'Filtered');

                end
                
            catch E
                throw(E);
            end
            
        end
        
        function plot = showDebugPlot(obj)
        %Function to plot all data in dataTable within a stacked plot, to
        %get a short overview over all existing data
            plot = stackedplot(obj.originalData,'-x');
        end
    end
    
    methods (Static)
        function density = waterDensity(temp)
        %Function to calculate the density of water at a specific temperature.
        %Input parameters:
        %   temp : temperature in °C
        %Returns a double containing the water density.
        %
        %Water density is herefore approximated by a parabolic function:
        %999.972-7E-3(T-4)^2
        
            if (nargin ~= 1)
                error('Not enough input arguments. One input parameter needed in °C as numeric or float.')
            end

            %Check if the variable experimentNo is numeric
            if ~isnumeric(temp)
                error(['Input parameter temperature needed in °C as numeric or float. Handed variable is class of: ',class(temp)])
            end
            
            density = 999.972-(temp-4).^2*0.007;
            
        end
    end

%% GETTER
    methods

        function rows = get.rows(obj)
            rows = obj.rows;
        end
        
        
        function experimentNo = get.experimentNo(obj)
            experimentNo = obj.experimentNo;
        end
        
        function data = getFilteredDataTable(obj)
            warning('This kind of access is possible but not recommended. Please use getter methods/functions to access data in this table!');
            data = obj.filteredData; %make timetable
        end
        
        function data = getOriginalDataTable(obj)
            warning('This kind of access is possible but not recommended. Please use getter methods/functions to access data in this table!');
            data = obj.originalData; %make timetable
        end
        
        
        function dataTable = getRoomTemperature(obj)
        %Returns a timetable with the following columns: runtime, timestamp, time_diff, room_t
            dataTable = obj.createTable();
            dataTable.room_t =obj.getAllTemperatures.room_t;
        end
        
        
        function dataTable = getAllTemperatures(obj)
        %Returns a timetable containing all temperature data. Missing
        %temperature datasets will be filled by linear interpolation
        %between the next neighboor.
            colNames = ''; %Variable for output-message containing column Names
            dataTable = obj.createTable;
            
            %Searching for all variables containing temperature data (°C)
            for i=1:width(obj.filteredData)
                if (strcmp(char(obj.filteredData(:,i).Properties.VariableUnits),'°C'))
                    colNames = strcat(colNames, obj.filteredData(:,i).Properties.VariableNames,{'; '});
                    dataTable = [dataTable obj.filteredData(:,i)];
                end
                
            end
            
            disp(strcat(class(obj), {' - '},  {'Found the following temperature related columns: '}, colNames));
        end
        
        
        function dataTable = getAllPressureRelative(obj)
        %Returns a timetable containing all relative pressure data: time, runtime
        %fluid_p_rel, hydrCylinder_p_rel, sigma2_3_p_rel
            dataTable = obj.createTable();
            dataTable = [dataTable obj.filteredData(:,{'fluid_p_rel', 'hydrCylinder_p_rel', 'sigma2_3_p_rel'})];
        end
        
        
        function dataTable = getAllPressureAbsolute(obj)
        %Returns a timetable containing all absolute pressure data: time, runtime
        %fluid_p_abs, hydrCylinder_p_abs, sigma2_3_p_abs
            dataTable = obj.createTable();
            dataTable = [dataTable obj.filteredData(:,{'room_p_abs', 'fluid_p_abs', 'hydrCylinder_p_abs', 'sigma2_3_p_abs'})];
        end
        
        
        function dataTable = getDeformationRelative(obj)
        %Returns a timetable containing deformation data of the specimen: time, runtime
        %deformation_1_s_rel, deformation_2_s_rel, deformation_mean
            dataTable = [obj.createTable() obj.filteredData(:,{'deformation_1_s_rel','deformation_2_s_rel',})];    

            %Calculating the mean deformation influenced by deformatoin
            %sensor 1 and 2. NaN entrys will be ignored.
            dataTable.deformation_mean = mean([dataTable.deformation_1_s_rel, dataTable.deformation_2_s_rel], 2, 'omitnan');
            dataTable.Properties.VariableUnits{'deformation_mean'} = 'mm';
            dataTable.Properties.VariableDescriptions {'deformation_mean'} = 'Mean relative deformation from sensor 1 and 2, zeroed at the beginning of the experiment';
        end
        
        
        function dataTable = getConfiningPressure(obj)
        %Returns a timetable containing confing pressure data: time, runtime, sigma2_3_p_rel
            dataTable = obj.createTable();  
            dataTable.sigma2_3_p_rel = obj.getAllPressureRelative.sigma2_3_p_rel;
            dataTable.Properties.VariableUnits{'sigma2_3_p_rel'} = obj.getAllPressureRelative.Properties.VariableUnits{'sigma2_3_p_rel'};
            dataTable.Properties.VariableDescriptions{'sigma2_3_p_rel'} = obj.getAllPressureRelative.Properties.VariableDescriptions{'sigma2_3_p_rel'};
        end
        
        
        function dataTable = getConfiningPressureRelative(obj)
        %DEPRECATED!!
        %Returns a timetable containing confing pressure data: time, runtime, sigma2_3_p_rel
            warning('Function getConfiningPressureRelative() deprecated. Use getConfiningPressure()')
        
            dataTable = obj.getConfiningPressure();
        end
        
        function dataTable = getBassinPumpData(obj)
        %Returns a timetable containing confing pressure data: time, runtime
        %pump_1_p, pump_2_p, pump_3_p, pump_mean_p, pump_1_V, pump_2_V, pump_3_V, pump_sum_V
        %
        %IMPORTANT:
        %The mean pump pressure has to be used with caution. When the
        %volume of a pump is empty, and it has to be refilled, there will
        %be a pressure loss!
            dataTable = [obj.createTable() obj.filteredData(:,{'pump_1_p','pump_1_V','pump_2_p','pump_2_V','pump_3_p','pump_3_V'})];
            
            %Calculating the mean pump pressure and volume influenced by
            %all three pumps. Ignoring NaN entrys.
            dataTable.pump_mean_p = mean([dataTable.pump_1_p, dataTable.pump_2_p, dataTable.pump_3_p],2,'omitnan');
            dataTable.Properties.VariableUnits{'pump_mean_p'} = dataTable.Properties.VariableUnits{'pump_1_p'};
            dataTable.Properties.VariableDescriptions{'pump_mean_p'} = 'Mean pressure measured internally in all pumps (relative value)';
            
            dataTable.pump_sum_V = sum([dataTable.pump_1_V, dataTable.pump_2_V, dataTable.pump_3_V],2,'omitnan');
            dataTable.Properties.VariableUnits{'pump_sum_V'} = dataTable.Properties.VariableUnits{'pump_1_V'};
            dataTable.Properties.VariableDescriptions{'pump_sum_V'} = 'Sum of present liquid in all pumps.';
        end
        
        
        
        function dataTable = getFlowData(obj)
        %Returns a timetable containing all flow data relevant data: time, runtime
        %weight, fluid_p_rel, fluid_out_t,
            dataTable = [obj.createTable() obj.filteredData(:,{'weight'})];
            
            tempData = obj.getAllTemperatures;
            dataTable.fluid_out_t = tempData.fluid_out_t;
            dataTable.Properties.VariableUnits{'fluid_out_t'} = tempData.Properties.VariableUnits{'fluid_out_t'};
            dataTable.Properties.VariableDescriptions{'fluid_out_t'} = tempData.Properties.VariableDescriptions{'fluid_out_t'};
            
            tempData= obj.getAllPressureRelative;
            dataTable.fluid_p_rel = tempData.fluid_p_rel;
            dataTable.Properties.VariableUnits{'fluid_p_rel'} = tempData.Properties.VariableUnits{'fluid_p_rel'};
            dataTable.Properties.VariableDescriptions{'fluid_p_rel'} = tempData.Properties.VariableDescriptions{'fluid_p_rel'};
        end
        
        function dataTable=getCalculationTable(obj)
        %DEPRECATED!!
        %Helperfunction to collect all relevant data for permeability
        %calculation. Calculates the density
        %Returns a timetable containing all flow data relevant data: time, runtime
        %weight, fluid_p_rel, fluid_out_t, deformation_mean and density
            warning('Function getCalculationTable is deprecated. Load the data directly without helper function!');
            
            dataTable = obj.getFlowData;
            
            tempData = obj.getDeformationRelative();
            dataTable.deformation_mean = tempData.deformation_mean;
            dataTable.Properties.VariableUnits{'deformation_mean'} = tempData.Properties.VariableUnits{'deformation_mean'};
            dataTable.Properties.VariableDescriptions{'deformation_mean'} = tempData.Properties.VariableDescriptions{'deformation_mean'};
            
            dataTable.density = obj.waterDensity(dataTable.fluid_out_t);
            dataTable.Properties.VariableUnits{'density'} = 'kg/m³';
            dataTable.Properties.VariableDescriptions{'density'} = 'Watedensity depening on the fluid temperature on the weight (fluid_out_t)';
        end 

        
        function permeability = getPermeability(obj, length, diameter, timestep, debug)                   
            %Input parameters:
            %   length : height of specimen in cm
            %   diameter: diameter of specimen in cm
            %   timestep: timestep between to calculation point of perm
            %   debug: all influencing parameters for permeability calculation
            %This function calculates the permeability and returns a
            %timetable containing the permeability and runtime. 
            %Fluid_p_rel and weight_diff outliers are detected using the mean method. Alpha is included.
            
            %Check for correct input parameters
            if nargin == 3
                warning('Set timestep to default: 5 minutes');
                timestep = 5;
                debug = false;
            end
            
            if nargin == 4
                debug = false;
            end
            
            if nargin == 5
                warning('Debug mode in getPermeability: all parameters as output');
            end
            
            if nargin < 3
                error('Not enough input arguments. specimen length; specimen diameter; timestep (optional)');
            end
            
            if ~isnumeric(length) || ~isnumeric(diameter) || ~isnumeric(timestep) || diameter <= 0 || length <= 0 || timestep <= 0 || isnan(diameter) || isnan(length)
                error('Input parameters length, diameter and timestep have to be numeric and bigger zero!');
            end
            
            %Catch all relevant data as timetable
            dataTable = obj.getFlowData;
            dataTable.deformation_mean = obj.getDeformationRelative.deformation_mean;
            dataTable.density = obj.waterDensity(dataTable.fluid_out_t);
            
            %Set length from cm to m
            length = length / 100;
            
            %Retime the dataTable to given timestep
            start = dataTable.time(1);
            time = (start:minutes(timestep):dataTable.time(end));
            dataTable = retime(dataTable,time,'linear');
            
            %Calculating differences
            dataTable.weight_diff = [0;max(0, diff(dataTable.weight))]; %Calculate weight difference between to entrys, no negative values are allows: max(0,value)
            dataTable.time_diff = [0;diff(dataTable.runtime)]; %Calculate time difference between to entrys
                                   
            %Add deltaL (variable) and A (constant)
            dataTable.deltaL = length - (dataTable.deformation_mean./1000);
            A = ((diameter/100)/2)^2*pi; %crosssection
            
            %Checking data for outliers
            %dataTable.fluid_p_rel = filloutliers(dataTable.fluid_p_rel,
            %'linear', 'mean'); % no longer needes. Is done in creator
            dataTable.weight_diff = filloutliers(dataTable.weight_diff, 'linear', 'movmean', [0 240]);
            dataTable.weight_diff = round(dataTable.weight_diff,3); %round to avoid spikes
           
            %Handling emptying the scale for the flow measurement
                %Split table if weight drops and weight difference between
                %to entrys in the given timestep is below zero
                weightDropPoints = find(dataTable.weight_diff<-0.01); %find where weight difference drops to below zero and count
                TF = isempty(weightDropPoints);

                weightDropPoints=[1; weightDropPoints]; %add starting index 1

                %Splitting up
                if TF==0
                    %split datatable where weight drops below zero
                    dataTable_Splitted = cell(numel(weightDropPoints)-1, 1); %create cell array in which to store the split tables
                    
                    for k=2:numel(weightDropPoints)
                        dataTable_Splitted{k-1} = dataTable(weightDropPoints(k-1):weightDropPoints(k)-1,:);
                    end
                
                    dataTable_Splitted{k,1} = dataTable(weightDropPoints(end):end,:); %add end section of table

                else
                    %create single cell array if weight does not drop below zero
                    dataTable_Splitted = cell(1,1);
                    dataTable_Splitted{1,1} = dataTable;
                    
                end
                
                %Calculating the permeability for each of the splitted data
                %tables
                for j = 1:numel(dataTable_Splitted)
                    tempTable = dataTable_Splitted{j,1}; %Save data in temporarily table
                    
                    g = 9.81; %Gravity m/s² or N/kg
                    
                    tempTable.h = (tempTable.fluid_p_rel .* 100000) ./ (tempTable.density .* g); %Pressure difference h between inflow and outflow in m
                    tempTable.WaterFlowVolume = (tempTable.weight_diff ./ tempTable.density); %water flow volume Q in m³
                    
                    tempTable.k = ((tempTable.WaterFlowVolume ./ seconds(tempTable.time_diff)) .* tempTable.deltaL) ./ (tempTable.h .* A); %calculate permeability
                    
                    %Normalize permeability to a reference temperature of 10 °C
                    tempTable.Itest = (0.02414 * 10.^((ones(size(tempTable.k)) * 247.8) ./ (tempTable.fluid_out_t + 133)));
                    tempTable.I_T = (0.02414 * 10.^((ones(size(tempTable.k)) * 247.8) ./ (10 + 133)));%Using reference temperature of 10 °C
                    tempTable.alpha = tempTable.Itest ./ tempTable.I_T;
                    tempTable.k_t = tempTable.k .* tempTable.alpha;
                    
                    dataTable_Splitted{j,1} = tempTable; %Save temp data in original table
                end
            
            %Assembly the dataTable_Splitted back into one dataTable
            dataTable = cat(1,dataTable_Splitted{:});
            
            %Create output timetable-variable
            if debug
                permeability = dataTable;
            else
                permeability = dataTable(:,{'runtime', 'weight_diff'});
            end
            permeability.permeability = dataTable.k_t;
            permeability.perm_alpha = dataTable.alpha;
                          
        end 
        
        function dataTable = getAnalytics(obj)
        %DEPRECATED!!
            warning('Function getCalculationTable is deprecated. Use getAnalyticsDataForGUI() instead!');
            dataTable = obj.getAnalyticsDataForGUI();
        end
        
        function dataTable = getAnalyticsDataForGUI(obj)
            %This function returns a table with all relevant data for
            %the GUI. This includes the weight, weight difference,
            %fluid pressure, hydraulic cylinder pressure, confining
            %pressure, bassin pump data, room temperature, fluid
            %temperature, deformation mean
            %All data will be synchronized and linear interpolated via
            %retime-function of the timetable.

            %get table and add neccessary variables    
            dataTable = obj.getFlowData;
            dataTable.deformation_mean = obj.getDeformationRelative.deformation_mean;
            dataTable.delta_deformation_1 = obj.getDeformationRelative.deformation_1_s_rel - dataTable.deformation_mean;
            dataTable.delta_deformation_2 = obj.getDeformationRelative.deformation_2_s_rel - dataTable.deformation_mean;
            dataTable.hydrCylinder_p_rel = obj.getAllPressureRelative.hydrCylinder_p_rel;
            dataTable.sigma2_3_p_rel = obj.getAllPressureRelative.sigma2_3_p_rel;
            dataTable.pump_sum = obj.getBassinPumpData.pump_sum_V;
            
            dataTable.room_t = fillmissing(obj.getAllTemperatures.room_t, 'linear');
            dataTable.fluid_out_t = fillmissing(dataTable.fluid_out_t, 'linear');
            dataTable.weight = fillmissing(dataTable.weight, 'previous');
            
            dataTable.density = obj.waterDensity(dataTable.fluid_out_t);
            %%%%%%%%%%%
            dataTable.weight_diff = [0; diff(dataTable.weight)]; %Is this correct???
            
            
            %It is possible to synchronize two timetables even if the data
            %is not consistent. The datatasets will be interpolized linear.
            %https://de.mathworks.com/help/matlab/matlab_prog/combine-timetables-and-synchronize-their-data.html
            %dataTable = synchronize(dataTable,permeability,);
                
        end 

    end
end 
 
