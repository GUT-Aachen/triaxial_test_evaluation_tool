classdef TriaxTestHandler < handle
    % This class creates the connection between the data sets and the GUI.
    
    properties %(GetAccess = private, SetAccess = private)
		listExperimentNo;
        experiment = struct('metaData', [], 'specimenData', [], 'testData', [], 'calculatedData', []); %Struct handling all experiments
        dbConnection; %Database connection
		labelList;
		waterProperties; %Struct for water properties from isantosruiz repo
		brewermap;
	end 
    
    %%
    
    methods (Static)
		
		function result = isinteger(value)
		%Check wether the input value is an integer or nor
		%Input parameters:
        %   value : any value
        %Returns true if value is an integer.
		
			try
				%Experiment number is an numeric-value?
				if ~isnumeric(value)
					result = false;

				%Experiment number is an integer-value?
				elseif ~mod(value,1) == 0
					result = false;

				else
					result = true;
				end
				
			catch E
				warning('%s: %s', class(obj), E.message);
				result = false;
			end
			
			
		end
    end
    
    %%
    
    methods (Access = private)
        function result = validateExperimentNoInput(obj, experimentNo)
        %Check if the variable experimentNo is an integer and if the
        %experiment number exists and is loaded allready.
        
            %Experiment number is an numeric-value?
			if ~obj.isinteger(experimentNo)
                result = ['Input "experimentNo" must consider a integer-variable. Handed variable is class of: ',class(experimentNo)];
				return
			end

			%Experiment exists in database?
			if ~sum(ismember(obj.listExperimentNo, experimentNo))
				result = ['Experiment number ', int2str(experimentNo), ' does not exist within the database.'];
				return
			end
            
            %Result true, if the test passes successfully
            result = true;
            
		end
        
        
        function result = calcFlowMassData (obj, experimentNo, timestep)
        % This function processes the incoming flow measurement data 
        % (flowMass). It calculates the weight difference between two time 
        % steps (flowMassDiff), the flow rate per time unit (flowRate), and 
        % the accumulated weight (flowMassAcc) based on the corrected differences.
        % A discontinuous system (scale with container) is used to measure the flow 
		% rate, which must be emptied several times during the test period (only large
		% triaxial test rig). The emptying causes jumps in the 
        % course of the measurement, which have to be eliminated. The 
        % elimination of the jumps is guaranteed by an outlier detection which 
        % checks whether there are deviations from a 'percentile' [3%<x>97%] in 
        % the measurement data. Since the flow rate remains relatively constant 
        % over time and is not subject to major fluctuations, viewing a quartile 
        % as an outlier provides perfect results.
        % For verification purposes, the measured flow (flowMass) can be 
        % compared with the accumulated flow (flowMassAcc). The course of 
        % the two curves must not differ significantly. The same applies to 
        % the difference per time step before and after smoothing.
        %
        % Input parameters:
        %   experimentNo : number of the experiment
        % Returns true to success
        
            disp([class(obj), ' - ', 'Calculating accumulated flow mass, flow mass difference per timestep and flow rate for experiment number ', int2str(experimentNo), ' (timestep = ', int2str(timestep), ').']);

            dataTable = obj.experiment(experimentNo).testData.getFlowData;
			
			%Retime if a particular timestep is given
			if ~timestep == 0
				start = dataTable.datetime(1);
				time = [(start:minutes(timestep):dataTable.datetime(end)) dataTable.datetime(end)];
				dataTable = retime(dataTable, time);
			end
			
            %Calculating differences
            dataTable.flowMassDiffOrig = [NaN; diff(dataTable.flowMass)]; %Calculate flowMass difference between to entrys
            dataTable.timeDiff = [NaN; diff(dataTable.runtime)]; %Calculate time difference between to entrys

            %Identify the outliers only for large triaxial tests
			%Size of the percentiles depends on the length of the experiment. Following numbers are empirically determinded.
			if obj.experiment(experimentNo).metaData.testRigData.id == 1
				
				durationHours = hours(obj.experiment(experimentNo).metaData.timeEnd - obj.experiment(experimentNo).metaData.timeStart);
				if durationHours > 150
					percentiles = [1 99];
				else
					percentiles = [5 95];
				end
				
				dataTable.flowMassDiff = filloutliers(dataTable.flowMassDiffOrig, 'linear', 'percentile', percentiles);
			else
				dataTable.flowMassDiff = dataTable.flowMassDiffOrig;
			end
			
            
            %Calculate comulated sum of mass differences
            dataTable.flowMassAcc = cumsum(dataTable.flowMassDiff, 'omitnan');

            %Calculate flow rate
            dataTable.flowRate = dataTable.flowMassDiff ./ obj.waterDensity(dataTable.fluidOutTemp) ./ seconds(dataTable.timeDiff);

            %Create output timetable-variable
            dataTable.Properties.VariableUnits{'flowMassDiffOrig'} = 'kg';
            dataTable.Properties.VariableDescriptions{'flowMassDiff'} = 'Difference of flow mass between two calculation steps (without outlier detection)';
            dataTable.Properties.VariableUnits{'flowMassDiff'} = 'kg';
            dataTable.Properties.VariableDescriptions{'flowMassDiff'} = 'Difference of flow mass between two calculation steps (with outlier detection)';
            dataTable.Properties.VariableUnits{'flowMassAcc'} = 'kg';
            dataTable.Properties.VariableDescriptions{'flowMassAcc'} = 'Accumulated fluid flow mass';
            dataTable.Properties.VariableUnits{'flowRate'} = 'm³/s';
            dataTable.Properties.VariableDescriptions{'flowRate'} = 'Flow rate through the sample';
			
			%Save dataTable in object
            obj.experiment(experimentNo).calculatedData.flowMass.data = dataTable;
			obj.experiment(experimentNo).calculatedData.flowMass.timestep = timestep;

            result = true;
		end
		
		
		
		function result = catchGraphData(obj, experimentNo, label, timestep)
		%Function catching a particular dataset and returning a struct of timetable, dataset label, dataset unit and a legend
		%entry for a plot. The output timetable will be in the given timestep. A timestep is only necessary for permeability.
		%In all other cases timestap is optional.
		%
        %Input parameters:
        %   experimentNo : number of the experiment
		%	label : label of the dataset
		%	timestep : output timestep
        %Returns a struct on success
			
			%Inputdata consistence checks            
			if (nargin < 3 || nargin > 4)
				error('%s: Not enough or too many input arguments. Two input parameters have to be handed over: experimentNo, label, timestep (optional)', class(obj));
			elseif nargin == 3
				timestep = [];
			end
			
			%Check if the variable experimentNo is valid
			validateExpNo = obj.validateExperimentNoInput(experimentNo);
			if ischar(validateExpNo)
				error('%s: %s is a string', class(obj), validateExpNo);
			end
			
			%Timestep dependent labels
			timestepDependency = {'permeability'};
			
			%Check if a label is given which needs a timestep input
			if sum(strcmp(label, timestepDependency))
				if isempty(timestep)
					error('%s: Label "%s" needs a timestep as input.', class(obj), label);
				end
			end
			
			if ~obj.isinteger(timestep)
				error('%s: input value timestep has to be a positive integer value', class(obj));
			elseif timestep < 0
				error('%s: input value timestep has to be a positive integer value.', class(obj));
			elseif timestep == 0
				timestep = [];
			end
			
			%Select case to determine which values are used and where to find the needed dataset
			switch label
				
				case 'runtime'  
					dataLabel = 'runtime';
					dataTable = obj.getFlowMassData(experimentNo);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.label = 'runtime';
					result.unit = 'hh:mm'; %'hh:mm';
					
				case 'permeabilityCoeff'
					dataLabel = 'permeabilityCoeff';
					dataTable = obj.getPermeability(experimentNo, timestep);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.label = 'permeability k_{f, 10°C}';
					result.unit = dataTable.Properties.VariableUnits(dataLabel);
					
				case 'permeability'
					dataLabel = 'permeability';
					dataTable = obj.getPermeability(experimentNo, timestep);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.label = 'permeability';
					result.unit = dataTable.Properties.VariableUnits(dataLabel);
					
				case 'permeabilityDarcy'
					dataLabel = 'permeability';
					dataTable = obj.getPermeability(experimentNo, timestep);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.data.permeability = result.data.permeability ./ 9.86923E-13 ./ 0.001;
					result.label = 'permeability';
					result.unit = 'mD';
                
				case 'strainSensor'
					dataLabel = 'strainSensorsMean';
					dataTable = obj.getStrain(experimentNo);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.label = 'probe compaction \epsilon';
					result.unit = dataTable.Properties.VariableUnits(dataLabel);
				
				case 'deformationPercentage'
					dataLabel = 'deformationPercentage';
					dataTable = obj.getStrain(experimentNo);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.label = 'probe compaction \epsilon';
					result.unit = dataTable.Properties.VariableUnits(dataLabel);
					
				case 'deformationPerMil'
					dataLabel = 'deformationPercentage';
					dataTable = obj.getStrain(experimentNo);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.data.deformationPercentage = result.data.deformationPercentage * 10;
					result.label = 'probe compaction \epsilon';
					result.unit = '‰';
					
				case 'strainSensor1'
					dataLabel = 'strainSensor1Rel';
					dataTable = obj.getStrain(experimentNo);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.label = 'deformation sensor 1 \epsilon_1';
					result.unit = dataTable.Properties.VariableUnits(dataLabel);
				
				case 'strainSensor2'
					dataLabel = 'strainSensor2Rel';
					dataTable = obj.getStrain(experimentNo);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.label = 'deformation sensor 2 \epsilon_2';
					result.unit = dataTable.Properties.VariableUnits(dataLabel);				
				
				case 'axialPressure'
					dataLabel = 'axialPressureRel';
					dataTable = obj.getPressureData(experimentNo);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.label = 'compaction pressure \sigma_1';
					result.unit = dataTable.Properties.VariableUnits(dataLabel);
				
				case 'axialPressureMPa'
					dataLabel = 'axialPressureRel';
					dataTable = obj.getPressureData(experimentNo);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.data.axialPressureRel = result.data.axialPressureRel * 10^-6;
					result.label = 'compaction pressure \sigma_1';
					result.unit = 'MPa';
					
				case 'axialPressureBar'
					dataLabel = 'axialPressureRel';
					dataTable = obj.getPressureData(experimentNo);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.data.axialPressureRel = result.data.axialPressureRel * 10^-5;
					result.label = 'compaction pressure \sigma_1';
					result.unit = 'bar';
					
					
				case 'axialForceT'
					dataLabel = 'axialPressureRelTonnes';
					dataTable = obj.getPressureData(experimentNo);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.data.axialPressureRelTonnes = result.data.axialPressureRelTonnes;
					result.label = 'compaction force';
					result.unit = 't';
				
				case 'hydrCylinderPressure'
					dataLabel = 'hydrCylinderPressureRel';
					dataTable = obj.getPressureData(experimentNo);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.label = 'hydr. cylinder \sigma_1';
					result.unit = dataTable.Properties.VariableUnits(dataLabel);
				
				case 'hydrCylinderPressureT'
					dataLabel = 'axialPressureRelTonnes';
					dataTable = obj.getPressureData(experimentNo);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.label = 'hydr. cylinder \sigma_1';
					result.unit = dataTable.Properties.VariableUnits(dataLabel);
				
				case 'hydrCylinderPressureMPa'  %Change values from bar to MPa
					dataLabel = 'hydrCylinderPressureRel';
					dataTable = obj.getPressureData(experimentNo);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.data.hydrCylinderPressureRel = result.data.hydrCylinderPressureRel * 0.1;
					result.label = 'hydr. cylinder pressure \sigma_1';
					result.unit = 'MPa';
					
				case 'fluidPressure'
					dataLabel = 'fluidPressureRel';
					dataTable = obj.getFlowMassData(experimentNo);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.label = 'fluid flow pressure';
					result.unit = dataTable.Properties.VariableUnits(dataLabel);
					
				case 'confiningPressure'
					dataLabel = 'confiningPressureRel';
					dataTable = obj.getPressureData(experimentNo);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.label = 'confining Pressure \sigma_{2/3}';
					result.unit = dataTable.Properties.VariableUnits(dataLabel);
					
				case 'confiningPressureMPa' %Change values from bar to MPa
					dataLabel = 'confiningPressureRel';
					dataTable = obj.getPressureData(experimentNo);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.data.confiningPressureRel = result.data.confiningPressureRel * 0.1;
					result.label = 'confining Pressure \sigma_{2/3}';
					result.unit = 'MPa';
					
				case 'confiningPumpVolume'
					dataLabel = 'pumpVolumeSum';
					dataTable = obj.getBassinPumpData(experimentNo);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.label = 'confining pressure pump volume';
					result.unit = dataTable.Properties.VariableUnits(dataLabel);
				
				case 'confiningPumpPressure'
					dataLabel = 'pumpPressureMean';
					dataTable = obj.getBassinPumpData(experimentNo);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.label = 'confining pressure pump \sigma_{2/3}';
					result.unit = dataTable.Properties.VariableUnits(dataLabel);
					
				case 'flowMass'
					dataLabel = 'flowMassAcc';
					dataTable = obj.getFlowMassData(experimentNo, timestep);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.label = 'flow mass';
					result.unit = dataTable.Properties.VariableUnits(dataLabel);
					
				case 'flowMassDiff'
					dataLabel = 'flowMassDiff';
					dataTable = obj.getFlowMassData(experimentNo, timestep);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.label = 'flow mass difference';
					result.unit = dataTable.Properties.VariableUnits(dataLabel);
				
				case 'flowRate'
					dataLabel = 'flowRate';
					dataTable = obj.getFlowMassData(experimentNo, timestep);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.label = 'flow rate Q';
					result.unit = dataTable.Properties.VariableUnits(dataLabel);
					
				case 'fluidOutTemp'
					dataLabel = 'fluidOutTemp';
					dataTable = obj.getTemperatures(experimentNo);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.label = 'fluid temperature (outflow) t_{fluid}';
					result.unit = dataTable.Properties.VariableUnits(dataLabel);
					
				case 'roomTemp'
					dataLabel = 'roomTemp';
					dataTable = obj.getTemperatures(experimentNo);
					result.data = dataTable(:,{'runtime', dataLabel});
					result.label = 'room temperature t_{room}';
					result.unit = dataTable.Properties.VariableUnits(dataLabel);

					
				otherwise
					warning([class(obj), ' - ', 'unknown columns']);
					dataTable = obj.getPressureData(experimentNo);
					nanTable = table(nan(size(dataTable, 1),1));
					result.data = [dataTable(:,{'runtime'}) nanTable];
					result.label = 'NaN';
					result.unit = 'NaN';
			end
			
			if ~isempty(result)
				try
					result.unit = strjoin(result.unit);
                catch
					
				end
				
				%Retime if a timestep is given
% 				if ~isempty(timestep) && ~strcmp(result.label, 'NaN')
% 					time = (dataTable.datetime(1) : minutes(timestep) : dataTable.datetime(end));
% 					result.data = retime(result.data, time, 'linear');
% 					
% 				elseif ~isempty(timestep) && strcmp(result.label, 'NaN')
% 					time = (dataTable.datetime(1) : minutes(timestep) : dataTable.datetime(end));
% 					result.data = retime(result.data, time);
% 					
% 				end
				
				result.legend = [result.label, ' [', result.unit,']'];
				result.data.Properties.VariableNames = {'runtime', 'dataset'}; %renaming columns in result to be uniform
			end
			
			
		end
        
    end
    
    %%
    methods
        function obj = TriaxTestHandler()
            import MeridDB.*
			%import BrewerMap/brewermap.*

            %Check if 'Curve Fitting Toolbox' is installed
            if ~license('test', 'Curve_Fitting_Toolbox')
                error('%s: Curve fitting toolbox is not installed on this system. Please install ', ...
                    'this toolbox in Matlab before using this tool.', class(obj));
            end
            
            dbUser = 'hiwi_ro';
            dbPassword = '#meridDB2019';
            serverIpAdress = '134.130.87.29';
            serverPort = 3306;
            
            %Initialize database
            obj.dbConnection = MeridDB(dbUser, dbPassword, serverIpAdress, serverPort);
			
			%Load list of all experiments
			obj.listExperimentNo = single(obj.getExperimentOverview.experimentNo);
			
			obj.labelList = containers.Map;
			obj.labelList('runtime') = 'Runtime';
			obj.labelList('permeabilityCoeff') = 'Permeability Coefficient [m/s]';
			obj.labelList('permeability') = 'Permeability [m²]';
			obj.labelList('permeabilityDarcy') = 'Permeability [mD]';
			obj.labelList('strainSensor') = 'Deformation [mm]';
			obj.labelList('deformationPercentage') = 'Deformation [%]';
			obj.labelList('deformationPerMil') = 'Deformation [‰]';
			obj.labelList('strainSensor1') = 'Strain Sensor 1';
			obj.labelList('strainSensor2') = 'Strain Sensor 2';
			obj.labelList('axialPressure') = 'Compaction Pressure [kN/m^2]';
			obj.labelList('axialPressureMPa') = 'Compaction Pressure [Mpa]';
			obj.labelList('axialPressureBar') = 'Compaction Pressure [bar]';
			obj.labelList('axialForceT') = 'Compaction Force [t]';
			obj.labelList('hydrCylinderPressure') = 'Hydr. Cylinder Pressure [bar]';
			obj.labelList('hydrCylinderPressureMPa') = 'Hydr. Cylinder Pressure [MPa]';
% 			obj.labelList('hydrCylinderPressureT') = 'Hydr. Cylinder Force [t]';
			obj.labelList('fluidPressure') = 'Flow Pressure';
			obj.labelList('confiningPressure') = 'Confining Pressure [bar]';
			obj.labelList('confiningPressureMPa') = 'Confining Pressure [MPa]';
			obj.labelList('confiningPumpVolume') = 'Volume in Pumps';
			obj.labelList('confiningPumpPressure') = 'Pressure in Pumps';
			obj.labelList('flowMass') = 'Fluid Mass';
			obj.labelList('flowMassDiff') = 'Fluid Difference';
			obj.labelList('flowRate') = 'Fluid Flow Rate';
			obj.labelList('fluidOutTemp') = 'Fluid Temperature Outflow';
			obj.labelList('roomTemp') = 'Room Temperature';
			
			% Load submodule water-properties
			try
				thisPath = fileparts(which([mfilename('class'),'.m'])); %Get the folder of the actual class file
				submodulePath = [thisPath, '/water-properties'];
				addpath(submodulePath)  % Add sobmodule path
				obj.waterProperties = water_properties;
				obj.waterProperties.density = obj.waterProperties.rho; %Load water properties as struct
				obj.waterProperties.viscosity = obj.waterProperties.nu; %Load water properties as struct
            catch E
				error('%s: Error while loading water_properties() from submodule water-properties/water-properties.m The submodule water-properties is missing. Get it from https://github.com/isantosruiz/water-properties \n(%s)', ...
                    class(obj), E.message);
			end
			
			% Load submodule BrewerMap
			try
				thisPath = fileparts(which([mfilename('class'),'.m'])); %Get the folder of the actual class file
				submodulePath = [thisPath, '/BrewerMap'];
				addpath(submodulePath)  % Add sobmodule path
				%obj.brewermap = brewermap;
				% obj.waterProperties = water_properties;
				% obj.waterProperties.density = obj.waterProperties.rho; %Load water properties as struct
				% obj.waterProperties.viscosity = obj.waterProperties.nu; %Load water properties as struct
            catch E
				error('%s: Error while loading BrewerMap from submodule BrewerMap/brewermap.m The submodule BrewerMap is missing. Get it from https://github.com/DrosteEffect/BrewerMap \n(%s)', ...
                    class(obj), E.message);
			end
			
		end
        
		function density = waterDensity(obj, temp)
        %Function to calculate the density of water at a specific temperature.
        %Input parameters:
        %   temp : temperature in °C
        %Returns a double containing the water density.
        %
        %If loopup table for density is not loaded the water density will be approximated by a parabolic function:
		%999.972-7E-3(T-4)^2
        
            if (nargin ~= 2)
                error('%s: Not enough input arguments. One input parameter needed in °C as numeric or float.', class(obj));
            end

            %Check if the variable experimentNo is numeric
            if ~isnumeric(temp)
                error('%s: Input parameter temperature needed in °C as numeric or float. Handed variable is class of: %s',class(obj), class(temp));
            end
            
			try
				density = obj.waterProperties.density(temp);
			catch
				density = 999.972-(temp-4).^2*0.007;
			end
            
		end
		
		
		function viscosity = waterViscosity(obj, temp)
		%Function returning the viscosity of water at a specific temperature. Viscosity is saved by lookup table in the
		%variable waterProperties.
		%Input parameters:
		%   temp : temperature in °C
		%Returns a double containing the water viscosity.
        
            if (nargin ~= 2)
                error('%s: Not enough input arguments. One input parameter needed in °C as numeric or float.', class(obj))
            end

            %Check if the variable experimentNo is numeric
			if ~isnumeric(temp)
                error('%s: Input parameter temperature needed in °C as numeric or float. Handed variable is class of: ',class(obj), class(temp))
			end
			
			try
				viscosity = obj.waterProperties.viscosity(temp);
			catch E
				viscosity = 1.0;
				warning('%s: Viscosity for water not loaded. Value set to 1.0. \n(%s)', class(obj), E.message);
			end
		end
		
		function result = isExperimentLoaded(obj, experimentNo)
        %Function checks, if the input experiment number is allready loaded
        %into this class.
        %
        %Input parameters:
        %   experimentNo : number of the experiment
        %Returns true if dataset is loaded
        
            try
                %Method to check if a particular experiment is allready loaded
                %into the experiment struct.
                if isa(obj.experiment(experimentNo).metaData, 'ExperimentsMetaData') && ...
                    isa(obj.experiment(experimentNo).specimenData, 'ExperimentsSpecimenData') && ...
                    isa(obj.experiment(experimentNo).testData, 'ExperimentsData')

                    result = true;
                else
                    result = false;
                end
            catch
                disp([class(obj), ' - ', 'Experiment number ', int2str(experimentNo), ' has not been loaded yet.']);
                result = false;
            end
            
        end
		
		
		function result = getLabelList(obj)
		%Returns a list of all available datasets to be plotted into a graph
			
			result = obj.labelList;
		end
		
		
		function result = getMetaData(obj, experimentNo)
			result = obj.experiment(experimentNo).metaData;
		end
		
		function result = getSpecimenData(obj, experimentNo)
			result = obj.experiment(experimentNo).specimenData;
		end
		
		
        function result = getExperimentOverview(obj)
        %Method loading all listed experiments from the database and
        %returning a list of all experiments including number, duration
        %and name
            result = obj.dbConnection.getExperiments;
        end
        
        function result = experimentExists(obj, experimentNo)
        %Method checking if an experiment with the given experiment
        %number exists.
        %
        %Input parameters:
        %   experimentNo : number of the experiment
        %Returns true if experiment exists
            
            result = obj.dbConnection.experimentExists(experimentNo);
        end
        
        
        
        function result = getLoadedExperiments(obj)
        %Returns a list of all loaded experiments
            
            result = [];
            
            for experimentNo = 1:numel(obj.experiment)
                if obj.isExperimentLoaded(experimentNo)
                    result = [result, experimentNo];
                end
            end 
        end
        
        
        function result = loadExperiment(obj, experimentNo)
        %Method to load a given experiment into the experiment struct.
        %
        %Input parameters:
        %   experimentNo : number of the experiment
        %Returns true if dataset is loaded
			
            %Check if the variable experimentNo is valid
            validateExpNo = obj.validateExperimentNoInput(experimentNo);
            if ischar(validateExpNo)
                error('%s: %s is a string', class(obj), validateExpNo);
            end
		
            try
                %Load meta data
                obj.experiment(experimentNo).metaData = obj.dbConnection.getMetaData(experimentNo);
                %Load specimen data
                specimenId = obj.experiment(experimentNo).metaData.specimenId;
                obj.experiment(experimentNo).specimenData = obj.dbConnection.getSpecimenData(experimentNo, specimenId);
                
                %Load test data
				%Limit test data to testing time from metadata
				formatOut = 'yyyy/mm/dd HH:MM:SS';
				timeStart = datestr(obj.experiment(experimentNo).metaData.timeStart, formatOut);
				timeEnd = datestr(obj.experiment(experimentNo).metaData.timeEnd, formatOut);
                obj.experiment(experimentNo).testData = obj.dbConnection.getExperimentData(experimentNo, timeStart, timeEnd); %, obj.experiment(experimentNo).metaData.timeStart, obj.experiment(experimentNo).metaData.timeEnd);
                
                %Set output variable to true if no error occured
                result = true;
            catch E
                warning('%s: Experiment number %d cannot be loaded. An error accured while catching the dataset from database. \n(%s)', ...
                    class(obj), experimentNo,  E.message);
                
                result = false;
            end 
		end
        
		function result = getGraphData(obj, experimentNo, xValue, y1Value, y2Value, timestep)
		%Returning a struct containing all necessary datasets and information for plotting a graph
			%Inputdata consistence checks
			%Check if there are two variables handed over
			if nargin < 4 || nargin > 6
				error('%s: Not enough or too many input arguments. One input parameter have to be handed over: experimentNo', class(obj));
			elseif nargin == 4
				y2Value = [];
				timestep = [];

			elseif nargin == 5
				timestep = [];

			end

			%Check if the variable experimentNo is valid
			validateExpNo = obj.validateExperimentNoInput(experimentNo);
			if ischar(validateExpNo)
				error('%s: %s is a string', class(obj), validateExpNo);
			end

			if ~isempty(xValue) && ~strcmp(xValue, 'none')
				xStruct = obj.catchGraphData(experimentNo, xValue, timestep);
				result.x = xStruct;
				result.x.data = xStruct.data.dataset;
			else
				error('%s: An x-axis value is mandatory!', class(obj));
			end

			if ~isempty(y1Value) && ~strcmp(y1Value, 'none')
				y1Struct = obj.catchGraphData(experimentNo, y1Value, timestep);

				result.y1 = y1Struct;
				result.y1.data = y1Struct.data.dataset;

				result.dataset = synchronize(xStruct.data(:,{'dataset'}), y1Struct.data(:,{'dataset'}), 'intersection');
				result.dataset.Properties.VariableNames = {'x', 'y1'}; %renaming columns in result to be uniform
			end

			if ~isempty(y2Value) && ~strcmp(y2Value, 'none')
				y2Struct = obj.catchGraphData(experimentNo, y2Value, timestep);

				result.y2 = y2Struct;
				result.y2.data = y2Struct.data.dataset;

				if ~isempty(y1Value)
					result.dataset = synchronize(result.dataset, y2Struct.data(:,{'dataset'}), 'intersection');
					result.dataset.Properties.VariableNames = {'x', 'y1', 'y2'}; %renaming columns in result to be uniform
				else
					result.dataset = synchronize(xStruct.data(:,{'dataset'}), y2Struct.data(:,{'dataset'}), 'intersection');
					result.dataset.Properties.VariableNames = {'x', 'y2'}; %renaming columns in result to be uniform
				end


			end

			if isempty(y1Value) && isempty(y2Value)
				error('%s: At least one y-axis value is mandatory!', class(obj));
			end
				
		end
		
		
        function result = getFlowMassData(obj, experimentNo, timestep, reCalc)
        %Returns a table containing all flow mass datasets
        %
        %Input parameters:
        %   experimentNo : number of the experiment
        %   reCalc: trigger to recalculate the flow mass dataset
        %Returns true if dataset is loaded
        
            %Inputdata consistence checks
            %Check if there are two variables handed over
			if nargin == 2
				timestep = 0;
                reCalc = false;
			end
			
			if nargin == 3
                reCalc = false;
			end
            
            if (nargin < 2)
                error('%s: Not enough input arguments. One input parameter have to be handed over: experimentNo (reCalc optional)', class(obj));
            end

            %Check if the variable experimentNo is valid
            validateExpNo = obj.validateExperimentNoInput(experimentNo);
            if ischar(validateExpNo)
                error('%s: %s is a string', class(obj), validateExpNo);
            end

            %Check if the variable recalc is true/false
            if ~islogical(reCalc)
                error('%s: Input "reCalc" must consider a logical-value. Handed variable is class of: %s', class(obj), class(reCalc))
            end
			
			%Check if the variable recalc is true/false
            if ~obj.isinteger(timestep)
				error('%s: Input "timestep" must consider a positive integer-value. Handed variable is class of: %s', class(obj), class(reCalc));
			elseif timestep < 0
				error('%s: Input "timestep" must consider a positive integer-value. Handed variable is class of: %s', class(obj) ,class(reCalc));
            end
        
            %Check if experiment is allready loaded
            if ~obj.isExperimentLoaded(experimentNo)
                warning('%s: Experiment number %d has not been loaded yet.', class(obj), experimentNo);
                result = [];
                return;
            end

            %Check if flowmass for given experiment has allready been
            %calculated
            if ~isfield(obj.experiment(experimentNo).calculatedData, 'flowMass') || reCalc
                %Calculate flow mass stuff
				disp([class(obj), ' - ', 'FlowMass recalculation necessary: no data available or recalculation forced']);
                obj.calcFlowMassData(experimentNo, timestep);
				
			%Check if the timestep corresponds to the given timestep
			elseif obj.experiment(experimentNo).calculatedData.flowMass.timestep ~= timestep
				%Calculate flow mass stuff
				disp([class(obj), ' - ', 'FlowMass recalculation necessary: timestep (', int2str(obj.experiment(experimentNo).calculatedData.flowMass.timestep), ') does not match (', int2str(timestep), ')']);
                obj.calcFlowMassData(experimentNo, timestep);
            end
            
            result = obj.experiment(experimentNo).calculatedData.flowMass.data;
        
        end
        
        function result = getRockDataTableContent(obj, experimentNo)
        %Preparing rock and specimen specific data to be printed into a
        %table in the gui. Names, values and units will be shown.
        %Input parameters:
        %   experimentNo : number of the experiment
        %Returns a table containing all specimen and rock data
            
            %Inputdata consistence checks            
            if (nargin ~= 2)
                error('%s: Not enough or too many input arguments. One input parameter have to be handed over: experimentNo', class(obj));
            end

            %Check if the variable experimentNo is valid
            validateExpNo = obj.validateExperimentNoInput(experimentNo);
            if ischar(validateExpNo)
                error('%s: %s is a string', class(obj), validateExpNo);
            end
        
            %Check whether the experiment has already been loaded.
            if ~obj.isExperimentLoaded(experimentNo)
                warning('%s: Experiment number %d has not been loaded yet.', class(obj), experimentNo);
                result = [];
                return;
            end
            
            %Loading rock data table
            specimenData = obj.experiment(experimentNo).specimenData;
            dataTable = table();
            
            %Creating the output table [name, value + unit]            
            dataTable = [dataTable; {'Experiment Number', num2str(specimenData.experimentNo)}];
            dataTable = [dataTable; {'Specimen Name', specimenData.specimen}];
            
            dataTable = [dataTable; {'Rock Name', specimenData.rockType}];
            dataTable = [dataTable; {'Rock Description', specimenData.rockDescription}];
            
            dataTable = [dataTable; {'Height', [num2str(specimenData.height.value, 4), ' ' , specimenData.height.unit]}];
            dataTable = [dataTable; {'Diameter', [num2str(specimenData.diameter.value, 4), ' ' , specimenData.diameter.unit]}];
            
            dataTable = [dataTable; {'Mass Saturated', [num2str((specimenData.massSaturated.value/1000), 4), ' ' , 'kg']}];
            dataTable = [dataTable; {'Mass Wet', [num2str((specimenData.massWet.value/1000), 4), ' ' , 'kg']}];
            dataTable = [dataTable; {'Mass Dry', [num2str((specimenData.massDry.value/1000), 4), ' ' , 'kg']}];
            
            dataTable = [dataTable; {'Density Wet', [num2str(specimenData.rockDensityWet.value, 3), ' ' , specimenData.rockDensityWet.unit]}];
            dataTable = [dataTable; {'Density Saturated', [num2str(specimenData.rockDensitySaturated.value, 3), ' ' , specimenData.rockDensitySaturated.unit]}];
            dataTable = [dataTable; {'Density Dry', [num2str(specimenData.rockDensityDry.value, 3), ' ' , specimenData.rockDensityDry.unit]}];
            dataTable = [dataTable; {'Density Grain', [num2str(specimenData.rockDensityGrain.value, 3), ' ' , specimenData.rockDensityGrain.unit]}];
            
            dataTable = [dataTable; {'Permeability Coefficient', [num2str(specimenData.permeabilityCoefficient.value, 2), ' ' , specimenData.permeabilityCoefficient.unit]}];
            dataTable = [dataTable; {'Porosity', [num2str(specimenData.porosity.value, 3), ' ' , specimenData.porosity.unit]}];
            dataTable = [dataTable; {'Void Ratio', [num2str(specimenData.voidRatio.value, 3), ' ' , specimenData.voidRatio.unit]}];
            
            dataTable = [dataTable; {'Uniaxial Compression Strength', [num2str(specimenData.uniAxialCompressiveStrength.value), ' ' , specimenData.uniAxialCompressiveStrength.unit]}];
            dataTable = [dataTable; {'Uniaxial E-Modulus', [num2str(specimenData.uniAxialEModulus.value), ' ' , specimenData.uniAxialEModulus.unit]}];
            
            result = dataTable;
        end
            
        function result = clearExperimentCache(obj)
        %Deleting all loaded experiments from the cache.
		%Returns true on success
            try
                obj.experiment = struct('metaData', [], 'specimenData', [], 'testData', [], 'calculatedData', []);
                result = true;
            catch
                warning('%s: Cache could not be cleared successfull!', class(obj));
                result = false;
            end
		end 
        
		function dataTable = getFilteredDataTable(obj, experimentNo)
		%Returns a timetable containing all available datasets for the given experiment number
			%Inputdata consistence checks            
			if (nargin ~= 2)
				error('%s: Not enough or too many input arguments. One input parameter have to be handed over: experimentNo', class(obj));
			end
		
			%Check if the variable experimentNo is valid
            validateExpNo = obj.validateExperimentNoInput(experimentNo);
			if ischar(validateExpNo)
                error('%s: %s is a string', class(obj), validateExpNo);
			end
			
            dataTable = obj.experiment(experimentNo).testData.getFilteredDataTable;
		end
		
		
		function dataTable = getOriginalDataTable(obj, experimentNo)
		%Returns a timetable containing all available datasets for the given experiment number (without filtering)
			%Inputdata consistence checks            
			if (nargin ~= 2)
				error('%s: Not enough or too many input arguments. One input parameter have to be handed over: experimentNo', class(obj));
			end
		
			%Check if the variable experimentNo is valid
            validateExpNo = obj.validateExperimentNoInput(experimentNo);
			if ischar(validateExpNo)
                error('%s: %s is a string', class(obj), validateExpNo);
			end
			
            dataTable = obj.experiment(experimentNo).testData.getOriginalDataTable;
		end
		
		function dataTable = getTemperatures(obj, experimentNo)
        %Returns a timetable containing all temperature data.
			%Inputdata consistence checks            
			if (nargin ~= 2)
				error('%s: Not enough or too many input arguments. One input parameter have to be handed over: experimentNo', class(obj));
			end
			
			%Check if the variable experimentNo is valid
            validateExpNo = obj.validateExperimentNoInput(experimentNo);
			if ischar(validateExpNo)
                error('%s: %s is a string', class(obj), validateExpNo);
			end
			
			dataTable = obj.experiment(experimentNo).testData.getAllTemperatures;
		end
		
		
		function dataTable = getPressureData(obj, experimentNo) 
        %Returns a timetable containing all relative pressure data: time, runtime
        %fluidPressureRel, hydrCylinderPressureRel, confiningPressureRel
			%Inputdata consistence checks            
			if (nargin ~= 2)
				error('%s: Not enough or too many input arguments. One input parameter have to be handed over: experimentNo', class(obj));
			end
		
			%Check if the variable experimentNo is valid
            validateExpNo = obj.validateExperimentNoInput(experimentNo);
			if ischar(validateExpNo)
                error('%s: %s is a string', class(obj), validateExpNo);
			end
			
			dataTable = obj.experiment(experimentNo).testData.getAllPressureRelative;
			
			%Calculate axial pressure and distinct between 250mm and 8mm probe
			diameter = obj.experiment(experimentNo).specimenData.diameter.value;
			A = (0.5 * 0.01 * diameter)^2 * pi();
			
			axialCylinderKgMax = obj.experiment(experimentNo).metaData.testRigData.axialCylinderKgMax;
			axialCylinderPMax = obj.experiment(experimentNo).metaData.testRigData.axialCylinderPMax / 100000;
			
			dataTable.axialPressureRel = (axialCylinderKgMax * 9.81 / axialCylinderPMax * dataTable.hydrCylinderPressureRel) ./ A;
			dataTable.axialPressureRelTonnes = axialCylinderKgMax / axialCylinderPMax * dataTable.hydrCylinderPressureRel ./ 1000;

			dataTable.Properties.VariableUnits{'axialPressureRel'} = 'N/m^2';
			dataTable.Properties.VariableDescriptions{'axialPressureRel'} = 'Axial pressure on probe';
			
			dataTable.Properties.VariableUnits{'axialPressureRelTonnes'} = 't';
			dataTable.Properties.VariableDescriptions{'axialPressureRelTonnes'} = 'Axial force on probe in tonnes';
		end
		
		function dataTable = getBassinPumpData(obj, experimentNo) 
        %Returns a timetable containing all relative pressure data: time, runtime
        %fluidPressureRel, hydrCylinderPressureRel, confiningPressureRel
			%Inputdata consistence checks            
			if (nargin ~= 2)
				error('%s: Not enough or too many input arguments. One input parameter have to be handed over: experimentNo', class(obj));
			end
		
			%Check if the variable experimentNo is valid
            validateExpNo = obj.validateExperimentNoInput(experimentNo);
			if ischar(validateExpNo)
                error('%s: %s is a string', class(obj), validateExpNo);
			end
			
			dataTable = obj.experiment(experimentNo).testData.getBassinPumpData;
		end
		
		function dataTable = getStrain(obj, experimentNo)
        %Returns a timetable containing deformation data of the specimen: time, runtime
        %strainSensor1Rel, strainSensor2Rel, strainSensorMean
		%Input parameters:
        %   experimentNo : number of the experiment
		%Returns a table containing all strain data
		
            %Inputdata consistence checks            
			if (nargin ~= 2)
				error('%s: Not enough or too many input arguments. One input parameter have to be handed over: experimentNo', class(obj));
			end

            %Check if the variable experimentNo is valid
            validateExpNo = obj.validateExperimentNoInput(experimentNo);
			if ischar(validateExpNo)
                error('%s: %s is a string', class(obj), validateExpNo);
			end
			
			%Check whether the experiment has already been loaded.
            if ~obj.isExperimentLoaded(experimentNo)
                warning('%s: Experiment number %d has not been loaded yet.', class(obj), experimentNo);
                dataTable = [];
                return;
            end
		
			dataTable = obj.experiment(experimentNo).testData.getDeformationRelative();    

            %Calculating the mean deformation influenced by deformatoin
            %sensor 1 and 2. NaN entrys will be ignored.
            dataTable.strainSensorsMean = mean([dataTable.strainSensor1Rel, dataTable.strainSensor2Rel], 2, 'omitnan');
            dataTable.Properties.VariableUnits{'strainSensorsMean'} = 'mm';
            dataTable.Properties.VariableDescriptions {'strainSensorsMean'} = 'Mean relative deformation from sensor 1 and 2, zeroed at the beginning of the experiment';
			
			dataTable.deformationPercentage = dataTable.strainSensorsMean ./ (obj.getSpecimenData(experimentNo).height.value * 10) * 100;
            dataTable.Properties.VariableUnits{'deformationPercentage'} = '%';
            dataTable.Properties.VariableDescriptions {'deformationPercentage'} = 'Mean relative deformation from sensor 1 and 2, zeroed at the beginning of the experiment, in relation to initial height';
		end
		
        function result = getPermeability(obj, experimentNo, timestep, debug)
        %This function calculates the permeability and returns a
        %timetable containing the permeability and runtime. Alpha is included.
        %Input parameters:
        %   experimentNo : number of the experiment
        %   timestep: timestep between to calculation point of perm
        %Returns a table containing permeability
			
			%Inputdata consistence checks      
			if (nargin < 2 || nargin > 4)
				error('%s: Not enough or too many input arguments.', class(obj));
			end
		
            %Check for correct input parameters
			if nargin == 2
                warning('%s: Set timestep to default: 5 minutes', class(obj));
                timestep = 5;
				debug = false;
            end
			
            if nargin == 3
                debug = false;
			end
            
            if nargin < 2
                error('%s: Not enough input arguments. One input parameter have to be handed over: experimentNo', class(obj));
            end

            %Check if the variable experimentNo is valid
            validateExpNo = obj.validateExperimentNoInput(experimentNo);
            if ischar(validateExpNo)
                error('%s: %s is a string', class(obj), validateExpNo);
            end
        
            %Check whether the experiment has already been loaded.
            if ~obj.isExperimentLoaded(experimentNo)
                warning('%s: Experiment number %d has not been loaded yet.', class(obj), experimentNo);
                result = [];
                return;
            end
            
            try
                %Catch all relevant data as timetable
                flowMassData = obj.getFlowMassData(experimentNo, timestep); % flow mass
				strainData = obj.getStrain(experimentNo); % probe deformation
				probeInitHeight = obj.experiment(experimentNo).specimenData.height.value/100; % probe height in m
				probeDiameter = obj.experiment(experimentNo).specimenData.diameter.value/100; % probe height in m
				
                dataTable = synchronize(flowMassData, strainData(:,'strainSensorsMean')); 
                
				%Check if fluid outflow temperature exists. Otherwise a standard temperature of 18°C will be used for further
				%calculations.
                if isnan(dataTable.fluidOutTemp)
                    dataTable.fluidOutTemp = zeros(size(dataTable,1),1)+18;
                    disp([class(obj), ' - ', 'Fluid outflow temperature set to 18°C.']);
                end
                dataTable.fluidDensity = obj.waterDensity(dataTable.fluidOutTemp); %get fluid (water) density
				dataTable.fluidViscosity = obj.waterViscosity(dataTable.fluidOutTemp); %get fluid (water) viscosity

                %Retime the dataTable to given timestep
                time = (dataTable.datetime(1) : minutes(timestep) : dataTable.datetime(end));
                dataTable = retime(dataTable,time,'linear');
				
				%Add probeHeight (variable) and crosssection area (constant)
				if isnan(dataTable.strainSensorsMean)
					dataTable.probeHeigth = zeros(size(dataTable,1),1) + probeInitHeight;
					disp([class(obj), ' - ', 'Due to missing deformation data the initial height of the sample is used.']);
				else
					dataTable.probeHeigth = probeInitHeight - (dataTable.strainSensorsMean ./ 1000);
				end
                crossSecArea = ((probeDiameter) / 2)^2 * pi; %crosssection


				gravity = 9.81; %Gravity m/s² or N/kg

				dataTable.deltaPressureHeight = (dataTable.fluidPressureRel .* 100000) ./ (dataTable.fluidDensity .* gravity); %Pressure difference h between inflow and outflow in m
				dataTable.fluidFlowVolume = (dataTable.flowMassDiff ./ dataTable.fluidDensity); %water flow volume Q in m³
				
				dataTable.permeability = ((dataTable.fluidFlowVolume ./ seconds(dataTable.timeDiff)) ... %calculate permeability
					.* dataTable.probeHeigth .* dataTable.fluidViscosity) ./ (dataTable.deltaPressureHeight .* crossSecArea);
				
				dataTable.permCoeff = ((dataTable.fluidFlowVolume ./ seconds(dataTable.timeDiff)) ... %calculate permeability coefficient
					.* dataTable.probeHeigth) ./ (dataTable.deltaPressureHeight .* crossSecArea); 
				dataTable.permCoeff = max(0, dataTable.permCoeff);

				%Normalize permeability to a reference temperature of 10 °C
				dataTable.Itest = (0.02414 * 10.^((ones(size(dataTable.permCoeff)) * 247.8) ./ (dataTable.fluidOutTemp + 133)));
				dataTable.IT = (0.02414 * 10.^((ones(size(dataTable.permCoeff)) * 247.8) ./ (10 + 133)));%Using reference temperature of 10 °C
				dataTable.alpha = dataTable.Itest ./ dataTable.IT;
				dataTable.permCoeffAlphaCorr = dataTable.permCoeff .* dataTable.alpha;
				
				%Create result table
				if debug
					permeability = dataTable;
				else
					permeability = dataTable(:,{'runtime'});
					
					permeability.permeability = dataTable.permeability;
					permeability.Properties.VariableUnits{'permeability'} = 'm²';
					permeability.Properties.VariableDescriptions{'permeability'} = 'Permeability';
					
					permeability.permeabilityCoeff = dataTable.permCoeffAlphaCorr;
					permeability.Properties.VariableUnits{'permeabilityCoeff'} = 'm/s';
					permeability.Properties.VariableDescriptions{'permeabilityCoeff'} = 'Coefficient of permeability alpha corrected to 10°C';

					permeability.alphaValue = dataTable.alpha;
					permeability.Properties.VariableUnits{'alphaValue'} = '-';
					permeability.Properties.VariableDescriptions{'alphaValue'} = 'Rebalancing factor to compare permeabilitys depending on the fluid temperature';
				end
				
				result = permeability;
			catch E
                warning('%s: Calculating permeability FAILED! \n(%s:%s)', class(obj), E.identifier, E.message);
                result = [];
            end
            
		end
		
		function result = getTimelog(obj, experimentNo)
			
			if ~isempty(obj.getMetaData(experimentNo).timelog)
				timelog = table2timetable(obj.getMetaData(experimentNo).timelog);
			
				result = timelog(:,{'retrospective', 'description'});
			else
				result = [];
			end
			
		end

	end
	
	
end

