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
	
    properties (SetAccess = immutable, GetAccess = private)
        originalData; %Dataset as timetable
    end
    
    properties (SetAccess = immutable)
        experimentNo; %Experiment number of the data
        rows;         %Number of entries on originalData/filteredData
	end

	properties (SetAccess = private, GetAccess = private)
        filteredData; %Filtered dataset as timetable
    end
    
    methods (Access = private)
        function dataTable = organizeTableData(obj, data, range)
        %This function is used to have specific names for each column, even
        %if the names in the database and therefore in the incomming data
        %stream changed. Additionaly the units, names and descriptions of
        %the columns will be added.		

            %Check if all columns are present and add units and description
            try
                %Initializing the timetable
				
				if ~isempty(range) && class(range) == "timerange"
					data = data(range,:);
				end
				
                dataTable = timetable(data.time);
                dataTable.Properties.DimensionNames{1} = 'datetime';  
                dataTable.datetime.Format = ('yyyy-MM-dd HH:mm:ss.SSS');
				
                vD.roomTemp = 'continuous';
                vD.fluidInTemp= 'continuous';
                vD.fluidOutTemp= 'continuous';
                vD.fluidPressure= 'continuous';
                vD.hydrCylinderPressure= 'continuous';
                vD.confiningPressure= 'continuous';
                vD.strainSensor1Pos= 'step';
                vD.strainSensor1Rel= 'step';
                vD.strainSensor2Pos= 'step';
                vD.strainSensor2Rel= 'step';
                vD.pump1Volume= 'step';
                vD.pump1Pressure= 'continuous';
                vD.pump2Volume= 'step';
                vD.pump2Pressure= 'continuous';
                vD.pump3Volume= 'step';
                vD.pump3Pressure= 'continuous';
                vD.flowMass= 'step';
                vD.runtime= 'continuous';
                
                %roomTemp: room temperatur
                if ismember('room_t', data.Properties.VariableNames)
                    dataTable.roomTemp = data.room_t;
                else
                    dataTable.roomTemp = NaN(size(data,1),1);
                    warning('%s: Room temperature (roomTemp) data missing. Added column filled with NaN.', class(obj));
                end
                if sum(isnan(dataTable.roomTemp)) == size(data,1) 
                    vD.roomTemp = 'unset';
                end
                dataTable.Properties.VariableUnits{'roomTemp'} = '°C';
                dataTable.Properties.VariableDescriptions{'roomTemp'} = 'Ambient air temperature';
                
                %fluidInTemp: inflow fluid temperature
                if ismember('fluid_in_t', data.Properties.VariableNames)
                    dataTable.fluidInTemp = data.fluid_in_t;
                else
                    dataTable.fluidInTemp = NaN(size(data,1),1);
                    warning('%s: Fluid inflow temperatur (fluidInTemp) data missing. Added column filled with NaN.', class(obj));
                end
                if sum(isnan(dataTable.fluidInTemp)) == size(data,1) 
                    vD.fluidInTemp = 'unset';
                end
                dataTable.Properties.VariableUnits{'fluidInTemp'} = '°C';
                dataTable.Properties.VariableDescriptions {'fluidInTemp'} = 'Temperature of the fluid before flowing the specimen.';

                %fluidOutTemp: outflow fluid temperature
                if ismember('fluid_out_t', data.Properties.VariableNames)
                    dataTable.fluidOutTemp = data.fluid_out_t;
                else
                    dataTable.fluidOutTemp = NaN(size(data,1),1);
                end
                if sum(isnan(dataTable.fluidOutTemp)) == size(data,1)
                    vD.fluidOutTemp = 'unset';
                    warning('%s: Fluid outflow temperatur (fluidOutTemp) data missing. Added column filled with NaN. Permeabilitycalculation will be imprecisely.', class(obj));
                end
                dataTable.Properties.VariableUnits{'fluidOutTemp'} = '°C';
                dataTable.Properties.VariableDescriptions {'fluidOutTemp'} = 'Temperature of the fluid after flowing through, meassured on the scale.';


                %fluidPressure: fluid pressure
                if ismember('fluid_in_p', data.Properties.VariableNames)
                    dataTable.fluidPressure = data.fluid_in_p;
                else
                    dataTable.fluidPressure = NaN(size(data,1),1);
                end
                if sum(isnan(dataTable.fluidPressure)) == size(data,1)
                    vD.fluidPressure = 'unset';
                    warning('%s: Fluid flow  pressure (fluidPressure) data missing. Permeability calculation not possible!', class(obj));
                end
                dataTable.Properties.VariableUnits{'fluidPressure'} = 'bar';
                dataTable.Properties.VariableDescriptions {'fluidPressure'} = 'Inflow pressure specimen';

                %hydrCylinderPressure: hydraulic cylinder pressure
                if ismember('hydrCylinder_p', data.Properties.VariableNames)
                    dataTable.hydrCylinderPressure = data.hydrCylinder_p;
                else
                    dataTable.hydrCylinderPressure = NaN(size(data,1),1);
                    warning('%s: Hydraulic cynlinder pressure (hydrCylinderPressureRel) data missing. Added column filled with NaN.', class(obj));
                end
                if sum(isnan(dataTable.hydrCylinderPressure)) == size(data,1) 
                    vD.hydrCylinderPressure = 'unset';
                end
                dataTable.Properties.VariableUnits{'hydrCylinderPressure'} = 'bar';
                dataTable.Properties.VariableDescriptions {'hydrCylinderPressure'} = 'Operating pressure of the hydraulic cylinder';

                %confiningPressure:  confining pressure
				%Sometimes the database returns the column name with an additional _1. This error is caught here.
                if ismember('confining_p', data.Properties.VariableNames) 
                    dataTable.confiningPressure = data.confining_p;
				elseif ismember('confining_p_1', data.Properties.VariableNames) % TODO: WHAT IS HAPPENING HERE?
                    dataTable.confiningPressure = data.confining_p_1;
                else
                    dataTable.confiningPressure = NaN(size(data,1),1);
                    warning('%s: Confining pressure (confiningPressure) data missing. Added column filled with NaN.', class(obj));
                end
                if sum(isnan(dataTable.confiningPressure)) == size(data,1) 
                    vD.confiningPressure = 'unset';
                end
                dataTable.Properties.VariableUnits{'confiningPressure'} = 'bar';
                dataTable.Properties.VariableDescriptions {'confiningPressure'} = 'Confining pressure in the bassin. Meassured at the inflow pipe';
                
                %strainSensor1Pos: absolute deformation sensor 1
                if ismember('deformation_1_s_abs', data.Properties.VariableNames)
                    dataTable.strainSensor1Pos = data.deformation_1_s_abs;
                else
                    dataTable.strainSensor1Pos = NaN(size(data,1),1);
                    warning('%s: Absolute deformation sensor 1 (strainSensor1Pos) data missing. Added column filled with NaN.', class(obj));
                end
                if sum(isnan(dataTable.strainSensor1Pos)) == size(data,1) 
                    vD.strainSensor1Pos = 'unset';
                end
                dataTable.Properties.VariableUnits{'strainSensor1Pos'} = 'mm';
                dataTable.Properties.VariableDescriptions {'strainSensor1Pos'} = 'Absolute deformation derived from the voltage';
                
                %strainSensor1Rel: relative deformation sensor 1
                if ismember('deformation_1_s_rel', data.Properties.VariableNames)
                    dataTable.strainSensor1Rel = data.deformation_1_s_rel;
				else
                    dataTable.strainSensor1Rel = NaN(size(data,1),1);
                    warning('%s: Relative deformation sensor 1 (strainSensor1Rel) data missing. Added column filled with NaN.', class(obj));
                end
                if sum(isnan(dataTable.strainSensor1Rel)) == size(data,1) 
					if sum(isnan(dataTable.strainSensor1Pos)) ~= size(data,1) %if relative strain is not given but absolute strain, take absolute strain and make it relative
						dataTable.strainSensor1Rel = dataTable.strainSensor1Pos - min(dataTable.strainSensor1Pos);
					else
						vD.strainSensor1Rel = 'unset';
					end
                end
                dataTable.Properties.VariableUnits{'strainSensor1Rel'} = 'mm';
                dataTable.Properties.VariableDescriptions {'strainSensor1Rel'} = 'Relative deformation, zeroed at the beginning of the experiment';
                                
                %strainSensor2Pos: absolute deformation sensor 2
                if ismember('deformation_2_s_abs', data.Properties.VariableNames)
                    dataTable.strainSensor2Pos = data.deformation_2_s_abs;
                else
                    dataTable.strainSensor2Pos = NaN(size(data,1),1);
                    warning('%s: Absolute deformation sensor 2 (strainSensor2Pos) data missing. Added column filled with NaN.', class(obj));
                end
                if sum(isnan(dataTable.strainSensor2Pos)) == size(data,1) 
                    vD.strainSensor2Pos = 'unset';
                end
                dataTable.Properties.VariableUnits{'strainSensor2Pos'} = 'mm';
                dataTable.Properties.VariableDescriptions {'strainSensor2Pos'} = 'Absolute deformation derived from the voltage';
                
                %strainSensor2Rel: relative deformation sensor 2
                if ismember('deformation_2_s_rel', data.Properties.VariableNames)
                    dataTable.strainSensor2Rel = data.deformation_2_s_rel;
				else
                    dataTable.strainSensor2Rel = NaN(size(data,1),1);
                    warning('%s: Relative deformation sensor 2 (strainSensor2Rel) data missing. Added column filled with NaN.', class(obj));
                end
                if sum(isnan(dataTable.strainSensor2Rel)) == size(data,1) 
					if sum(isnan(dataTable.strainSensor2Pos)) ~= size(data,1) %if relative strain is not given but absolute strain, take absolute strain and make it relative
						dataTable.strainSensor2Rel = dataTable.strainSensor2Pos - min(dataTable.strainSensor2Pos);
					else
						vD.strainSensor2Rel = 'unset';
					end
                end
                dataTable.Properties.VariableUnits{'strainSensor2Rel'} = 'mm';
                dataTable.Properties.VariableDescriptions {'strainSensor2Rel'} = 'Relative deformation, zeroed at the beginning of the experiment';
                
                %Check if any relative deformation is given
                if sum(isnan(dataTable.strainSensor1Rel)) == size(data,1) && sum(isnan(dataTable.strainSensor2Rel)) == size(data,1)
                    warning('%s: Deformation relative data missing (strainSensor1Rel and strainSensor2Rel) data missing. Permeability calculation not possible!', class(obj));
                end

                %pump1Volume: volume pump 1
                if ismember('pump_1_V', data.Properties.VariableNames)
                    dataTable.pump1Volume = data.pump_1_V;
                else
                    dataTable.pump1Volume = NaN(size(data,1),1);
                    warning('%s: Volume Pump 1 (pump1Volume) data missing. Added column filled with NaN.', class(obj));
                end
                if sum(isnan(dataTable.pump1Volume)) == size(data,1) 
                    vD.pump1Volume = 'unset';
                end
                dataTable.Properties.VariableUnits{'pump1Volume'} = 'ml';
                dataTable.Properties.VariableDescriptions {'pump1Volume'} = 'Liquid present in the pump';

                %pump1Pressure: pressure pump 1
                if ismember('pump_1_V', data.Properties.VariableNames)
                    dataTable.pump1Pressure = data.pump_1_V;
                else
                    dataTable.pump1Pressure = NaN(size(data,1),1);
                    warning('%s: Pressure Pump 1 (pump1Pressure) data missing. Added column filled with NaN.', class(obj));
                end 
                if sum(isnan(dataTable.pump1Pressure)) == size(data,1) 
                    vD.pump1Pressure = 'unset';
                end
                dataTable.Properties.VariableUnits{'pump1Pressure'} = 'bar';
                dataTable.Properties.VariableDescriptions {'pump1Pressure'} = 'Pressure measured internally in the pump';

                %pump2Volume: volume pump 2
                if ismember('pump_2_V', data.Properties.VariableNames)
                    dataTable.pump2Volume = data.pump_2_V;
                else
                    dataTable.pump2Volume = NaN(size(data,1),1);
                    warning('%s: Volume Pump 2 (pump2Volume) data missing. Added column filled with NaN.', class(obj));
                end
                if sum(isnan(dataTable.pump2Volume)) == size(data,1) 
                    vD.pump2Volume = 'unset';
                end
                dataTable.Properties.VariableUnits{'pump2Volume'} = 'ml';
                dataTable.Properties.VariableDescriptions {'pump2Volume'} = 'Liquid present in the pump';

                %pump2Pressure: pressure pump 2
                if ismember('pump_2_p', data.Properties.VariableNames)
                    dataTable.pump2Pressure = data.pump_2_p;
                else
                    dataTable.pump2Pressure = NaN(size(data,1),1);
                    warning('%s: Pressure Pump 2 (pump2Pressure) data missing. Added column filled with NaN.', class(obj));
                end    
                if sum(isnan(dataTable.pump2Pressure)) == size(data,1) 
                    vD.pump2Pressure = 'unset';
                end
                dataTable.Properties.VariableUnits{'pump2Pressure'} = 'bar';
                dataTable.Properties.VariableDescriptions {'pump2Pressure'} = 'Pressure measured internally in the pump';

                %pump3Volume: volume pump 3
                if ismember('pump_3_V', data.Properties.VariableNames)
                    dataTable.pump3Volume = data.pump_3_V;
                else
                    dataTable.pump3Volume = NaN(size(data,1),1);
                    warning('%s: Volume Pump 3 (pump3Volume) data missing. Added column filled with NaN.', class(obj));
                end
                if sum(isnan(dataTable.pump3Volume)) == size(data,1) 
                    vD.pump3Volume = 'unset';
                end
                dataTable.Properties.VariableUnits{'pump3Volume'} = 'ml';
                dataTable.Properties.VariableDescriptions {'pump3Volume'} = 'Liquid present in the pump';

                %pump3Pressure: pressure pump 3
                if ismember('pump_3_p', data.Properties.VariableNames)
                    dataTable.pump3Pressure = data.pump_3_p;
                else
                    dataTable.pump3Pressure = NaN(size(data,1),1);
                    warning('%s: Pressure Pump 3 (pump3Pressure) data missing. Added column filled with NaN.', class(obj));
                end  
                if sum(isnan(dataTable.pump3Pressure)) == size(data,1) 
                    vD.pump3Pressure = 'unset';
                end
                dataTable.Properties.VariableUnits{'pump3Pressure'} = 'bar';
                dataTable.Properties.VariableDescriptions {'pump3Pressure'} = 'Pressure measured internally in the pump';
                
                %flowMass: flowMass of the water
                if ismember('weight', data.Properties.VariableNames)
                    dataTable.flowMass = data.weight;
                else
                    dataTable.flowMass = NaN(size(data,1),1);
                end
                
                if sum(isnan(dataTable.flowMass)) == size(data,1)
                    vD.flowMass = 'unset';
                    warning('%s: Weight from scale (flowMass) data missing. Added column filled with NaN. Permeability calculation not possible!', class(obj));
                end
                dataTable.Properties.VariableUnits{'flowMass'} = 'kg';
                dataTable.Properties.VariableDescriptions {'flowMass'} = 'Weight of the water meassured on the scale';
                
            catch E
                error('%s: The given dataset is missing a column or properties can not be added. Please control the given data to be complete.', class(obj));
            end
            
            %Recast time-String to datetime, calculate time dependend
            %variables like runtime and convert to timetable
            try
                %Set variable continuity for synchronizing data
                %time is unset, should not be filled
                %pressure and temperature are continious
                %deformation related meassurements are stepwise
                %volume in pumps is stepwise
                %flowMass on scale is stepwise
				
				dataTable.Properties.VariableContinuity = { vD.roomTemp , ...
                    vD.fluidInTemp ,vD.fluidOutTemp ,vD.fluidPressure, ...
                    vD.hydrCylinderPressure ,vD.confiningPressure , ...
                    vD.strainSensor1Pos ,vD.strainSensor1Rel ,vD.strainSensor2Pos , ...
                    vD.strainSensor2Rel ,vD.pump1Volume ,vD.pump1Pressure ,vD.pump2Volume ,vD.pump2Pressure , ...
                    vD.pump3Volume ,vD.pump3Pressure ,vD.flowMass};
                dataTable = retime(dataTable, 'secondly', 'endvalues', NaN);
                
                %Calculate runtime
                rt = table(dataTable.datetime);
                dataTable.runtime = seconds(seconds(rt{:,1}-rt{1:1,1})); %working with datetime
                dataTable.Properties.VariableUnits{'runtime'} = 's';
                dataTable.Properties.VariableDescriptions{'runtime'} = 'Runtime in seconds since experiment start';
                
            catch E
                error('%s: Can not add runtime to timetable and/or calculate time difference', class(obj));
            end
            
        end
        
        
        function dataTable = filterTableData(obj, data, range)
        %This function is used to filter most of the data
            
            %Prepare input for return, changed in data like filtering are
            %going to update the data in dataTable
            dataTable = data;
			
			if (nargin < 2 || nargin > 3)
				error('%s: Not enough or too many input arguments. Two input parameters have to be handed over: data, range (optional)', class(obj));
			elseif nargin == 2
				range = [];
			end
			
			if ~isempty(range) && class(range) == "timerange"
				dataTable.data = dataTable.data(range,:);
			end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %PRESSURE
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            try				
				if (sum(isnan(dataTable.confiningPressure)) ~= length(dataTable.confiningPressure)) %Check if all data is NaN
					dat = data.confiningPressure;
					dat = movmedian(dat, 7, 'omitnan');
					dataTable.confiningPressure = round(dat, 2);
				end

            catch
                warning('%s: error while filtering confiningPressure', class(obj));
			end

            
            try
				if (sum(isnan(dataTable.hydrCylinderPressure)) ~= length(dataTable.hydrCylinderPressure)) %Check if all data is NaN
					dat = data.hydrCylinderPressure;
					dat = movmedian(dat, 3, 'omitnan');
					dataTable.hydrCylinderPressure = round(dat, 2);
				end

            catch
                warning('%s: Error while filtering hydrCylinderPressure', class(obj));
            end
            
            try				
				if (sum(isnan(dataTable.fluidPressure)) ~= length(dataTable.fluidPressure)) %Check if all data is NaN
					dat = data.fluidPressure;
					dat = movmedian(dat, 9, 'omitnan');
					dataTable.fluidPressure = round(dat, 4);
				end

            catch
                warning('%s: Error while filtering fluidPressure', class(obj));
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %TEMPERATURES
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %PT100 Temperatures as filtered by movmedian
            try
				if (sum(isnan(dataTable.fluidInTemp)) ~= length(dataTable.fluidInTemp)) %Check if all data is NaN
					dat = data.fluidInTemp;
					dat = filloutliers(dat, 'nearest', 'movmedian', 180);
					dat = fillmissing(dat, 'nearest');
					dat = movmedian(dat, 600, 'omitnan');
					dataTable.fluidInTemp = round(dat, 2);
				end

            catch
                warning('%s: Error while filtering fluidInTemp', class(obj));
            end
            
            try
				if (sum(isnan(dataTable.fluidOutTemp)) ~= length(dataTable.fluidOutTemp)) %Check if all data is NaN
					dat = data.fluidOutTemp;
					dat = filloutliers(dat, 'nearest', 'movmedian', 180);
					dat = fillmissing(dat, 'nearest');
					dat = movmedian(dat, 600, 'omitnan');
					dataTable.fluidOutTemp = round(dat, 2);
				end

            catch
                warning('%s: Error while filtering fluidOutTemp', class(obj));
            end
            
            try
				if (sum(isnan(dataTable.fluidOutTemp)) ~= length(dataTable.fluidOutTemp)) %Check if all data is NaN
					dat = data.roomTemp;
					dat = filloutliers(dat, 'nearest', 'movmedian', 180);
					dat = fillmissing(dat, 'nearest');
					dat = movmedian(dat, 600, 'omitnan');
					dataTable.roomTemp = round(dat, 2);
				end

            catch
                warning('%s: Error while filtering roomTemp', class(obj));
            end
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %DEFORMATION
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Filtering of deformation must be used carefully, as we have a
            %changed deformation meassurement system
            %Check if a absulote deformation is given. Otherwise the
            %relative deformation will be saved as abs and the corected
            % (nulled) value will be saved as rel.
            try
				if (sum(isnan(dataTable.strainSensor1Rel)) == length(dataTable.strainSensor1Rel)) %Check if all relative data is NaN
					if ~(sum(isnan(dataTable.strainSensor1Pos)) == length(dataTable.strainSensor1Pos)) %Check if all absolute data is NaN
						dat = movmedian(data.strainSensor1Pos, 30, 'omitnan');
						dataTable.strainSensor1Pos = round(dat, 3);

						dataTable.strainSensor1Rel = round(dat - min(dat), 3);
					end
				else
					dat = movmedian(data.strainSensor1Rel, 30, 'omitnan');
					dataTable.strainSensor1Rel = round(dat, 3);
				end
                
            catch
                warning('%s: Error while filtering strainSensor1Pos/strainSensor1Rel', class(obj));
            end
            
            try
				if (sum(isnan(dataTable.strainSensor2Rel)) == length(dataTable.strainSensor2Rel)) %Check if all relative data is NaN
					if ~(sum(isnan(dataTable.strainSensor2Pos)) == length(dataTable.strainSensor2Pos)) %Check if all absolute data is NaN
						dat = movmedian(data.strainSensor2Pos, 30, 'omitnan');
						dataTable.strainSensor2Pos = round(dat, 3);

						dataTable.strainSensor2Rel = round(dat - min(dat), 3);
					end
				else
					dat = movmedian(data.strainSensor2Rel, 30, 'omitnan');
					dataTable.strainSensor2Rel = round(dat, 3);
				end
            catch
                warning('%s: Error while filtering strainSensor2Pos/strainSensor2Rel', class(obj));
            end
            
        end
        
        function dataTable = createTable(obj)
        %Function to create a timetable constisting of the runtime only
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
                    error('%s: Not enough input arguments. Two input parameters have to be handed over: experimentNo as Integer and data as timetable.', class(obj))
                end

                %Check if the variable experimentNo is numeric
                if ~isnumeric(experimentNo)
                    error('%s: Input "experimentNo" must consider a numeric-variable. Handed variable is class of: %s',class(obj), class(experimentNo))
                end

                %Check if the variable data is a table
                if ~istimetable(data)
                    error('%s: Input "data" must consider a timetable-variable. Handed variable is class of: %s',class(obj), class(data))
                end

                %Check if the data table is empty
                if height(data) == 0
                    error('%s: data table for the experiment is empty', class(obj))
                end
            
            %Saving original data in object
            obj.originalData = data;
                
            %Organize all data in the table: adding units and desciptions
            %Convert from table to timetable
            obj.updateDataTable;
            
            %Saving variables in actual object
            obj.experimentNo = experimentNo; 
            obj.rows = height(data);
            
		end
        
		function result = updateDataTable(obj, range)
			
			if (nargin < 1 || nargin > 2)
				error('%s: Not enough or too many input arguments. Two input parameters have to be handed over: range (optional)', class(obj));
			elseif nargin == 1
				range = [];	
			end
			
			%Saving original data in object
            dataTable = obj.originalData;
                
            %Organize all data in the table: adding units and desciptions
            %Convert from table to timetable
			disp(strcat(class(obj), {' - '},  {'Reorganizing experiments data'}));
            dataTable = obj.organizeTableData(dataTable, range);
			
			%Filter all data
			disp(strcat(class(obj), {' - '},  {'Filtering experiments data'}));
            obj.filteredData = obj.filterTableData(dataTable);
			
			result = true;
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

                            figTemp = figure;
                            plot(x1,y1,':' ,x2,y2);
                            title(variables(k), 'Interpreter', 'none');
                            legend('Original', 'Filtered');

                            fig = [fig, figTemp];
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


%% GETTER
    methods

        function rows = get.rows(obj)
            rows = obj.rows;
        end
        
        
        function experimentNo = get.experimentNo(obj)
            experimentNo = obj.experimentNo;
        end
        
        function data = getFilteredDataTable(obj)
            warning('%s: This kind of access is possible but not recommended. Please use getter methods/functions to access data in this table!', class(obj));
            data = obj.filteredData; %make timetable
        end
        
        function data = getOriginalDataTable(obj)
            warning('%s: This kind of access is possible but not recommended. Please use getter methods/functions to access data in this table!', class(obj));
            data = obj.originalData; %make timetable
        end
        
        
        function dataTable = getRoomTemperature(obj)
        %Returns a timetable with the following columns: runtime, timestamp, timeDiff, roomTemp
            dataTable = obj.createTable();
            dataTable = [dataTable obj.filteredData(:,{'roomTemp'})];
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
		% DEPRECATED FUNCTION
			dataTable = getAllPressure(obj);
		end
		
        function dataTable = getAllPressure(obj)
        %Returns a timetable containing all pressure data: time, runtime
        %fluidPressureRel, hydrCylinderPressureRel, confiningPressureRel
            dataTable = obj.createTable();
            dataTable = [dataTable obj.filteredData(:,{'fluidPressure', 'hydrCylinderPressure', 'confiningPressure'})];
        end
                
		
        function dataTable = getDeformationRelative(obj)
        %Returns a timetable containing deformation data of the specimen: time, runtime
        %strainSensor1Rel, strainSensor2Rel, strainSensorMean
            dataTable = [obj.createTable() obj.filteredData(:,{'strainSensor1Rel','strainSensor2Rel',})];    

        end
        
        
        function dataTable = getConfiningPressure(obj)
        %Returns a timetable containing confing pressure data: time, runtime, confiningPressure
            dataTable = obj.createTable();  
            dataTable.confiningPressure = obj.getAllPressureRelative.confiningPressure;
            dataTable.Properties.VariableUnits{'confiningPressure'} = obj.getAllPressureRelative.Properties.VariableUnits{'confiningPressure'};
            dataTable.Properties.VariableDescriptions{'confiningPressure'} = obj.getAllPressureRelative.Properties.VariableDescriptions{'confiningPressure'};
        end
        
        
        function dataTable = getBassinPumpData(obj)
        %Returns a timetable containing confing pressure data: time, runtime
        %pump1Pressure, pump2Pressure, pump3Pressure, pumpPressureMean, pump1Volume, pump2Volume, pump3Volume, pumpVolumeSum
        %
        %IMPORTANT:
        %The mean pump pressure has to be used with caution. When the
        %volume of a pump is empty, and it has to be refilled, there will
        %be a pressure loss!
            dataTable = [obj.createTable() obj.filteredData(:,{'pump1Pressure','pump1Volume','pump2Pressure','pump2Volume','pump3Pressure','pump3Volume'})];
            
            %Calculating the mean pump pressure and volume influenced by
            %all three pumps. Ignoring NaN entrys.
            dataTable.pumpPressureMean = mean([dataTable.pump1Pressure, dataTable.pump2Pressure, dataTable.pump3Pressure],2,'omitnan');
            dataTable.Properties.VariableUnits{'pumpPressureMean'} = dataTable.Properties.VariableUnits{'pump1Pressure'};
            dataTable.Properties.VariableDescriptions{'pumpPressureMean'} = 'Mean pressure measured internally in all pumps';
            
            dataTable.pumpVolumeSum = sum([dataTable.pump1Volume, dataTable.pump2Volume, dataTable.pump3Volume],2,'omitnan');
            dataTable.Properties.VariableUnits{'pumpVolumeSum'} = dataTable.Properties.VariableUnits{'pump1Volume'};
            dataTable.Properties.VariableDescriptions{'pumpVolumeSum'} = 'Sum of present liquid in all pumps.';
        end
           
        
        function dataTable = getFlowData(obj)
        %Returns a timetable containing all flow data relevant data: time, runtime
        %flowMass, fluidPressureRel, fluidOutTemp,
            dataTable = [obj.createTable() obj.filteredData(:,{'flowMass'})];
            
            tempData = obj.getAllTemperatures;
            dataTable.fluidOutTemp = tempData.fluidOutTemp;
            dataTable.Properties.VariableUnits{'fluidOutTemp'} = tempData.Properties.VariableUnits{'fluidOutTemp'};
            dataTable.Properties.VariableDescriptions{'fluidOutTemp'} = tempData.Properties.VariableDescriptions{'fluidOutTemp'};
            
			dataTable.fluidInTemp = tempData.fluidInTemp;
            dataTable.Properties.VariableUnits{'fluidInTemp'} = tempData.Properties.VariableUnits{'fluidInTemp'};
            dataTable.Properties.VariableDescriptions{'fluidInTemp'} = tempData.Properties.VariableDescriptions{'fluidInTemp'};
			
            tempData= obj.getAllPressure;
            dataTable.fluidPressure = tempData.fluidPressure;
            dataTable.Properties.VariableUnits{'fluidPressure'} = tempData.Properties.VariableUnits{'fluidPressure'};
            dataTable.Properties.VariableDescriptions{'fluidPressure'} = tempData.Properties.VariableDescriptions{'fluidPressure'};
		end

    end
end 
 
