classdef ExperimentsSpecimenData < handle
%Class to handle the rock data of MERID triaxial experiments. The
%experiment number has to be given while creating the class object.
%All metadata information like start and end time, comments or a
%description can be read directly from the class.
%Within the class the data will be saved in a table (metaDataTable). All
%depending variables like (description, short, etc.) are empty. They are some kind of
%proxy values to be able to work with the values as if they where saved in
%the variables.
%
% Biebricher 2019-05-13
%   * Added variable massWet incl. getter
% Biebricher 2019-10-22
%   * Match camelCase
% Biebricher 2019-10-25
%   * Properties as struct containing of value/unit pair
% Biebricher 2019-11-04
%	* Added getDataTable() to get all specimen information as a table at once
    
    properties (SetAccess = immutable)
        experimentNo; %Number of the experiment the data in this object contains to.
    end
    
    properties (SetAccess = private)
        specimen; %Proxyvariable for name of specimen in rockdata. Data is only saved in rockDataTable.
        rockType; %Proxyvariable for name of rock in rockdata. Data is only saved in rockDataTable.
        rockDescription; %Proxyvariable for rock description in rockdata. Data is only saved in rockDataTable.
        height; %Proxyvariable for height of specimen in rockdata. Data is only saved in rockDataTable.
        diameter; %Proxyvariable for diameter of specimen in rockdata. Data is only saved in rockDataTable.
        massSaturated; %Proxyvariable for mass of saturated specimen in rockdata. Data is only saved in rockDataTable.
        massWet; %Proxyvariable for mass of wet specimen in rockdata. Data is only saved in rockDataTable.
        massDry; %Proxyvariable for mass of dry specimen in rockdata. Data is only saved in rockDataTable.
        rockDensityWet; %Proxyvariable for wet rock density in rockdata. Data is only saved in rockDataTable.
        rockDensitySaturated; %Proxyvariable for wet rock density in rockdata. Data is only saved in rockDataTable.
        rockDensityDry; %Proxyvariable for wet rock density in rockdata. Data is only saved in rockDataTable.
        rockDensityGrain; %Proxyvariable for wet rock density in rockdata. Data is only saved in rockDataTable.
        densityDry;
        densitySaturated;
        permeabilityCoefficient; %Proxyvariable for permeability coefficient of rock in rockdata. Data is only saved in rockDataTable.
        porosity; %Proxyvariable for porosity of rock in rockdata. Data is only saved in rockDataTable.
        voidRatio; %Proxyvariable for void ratio of rock in rockdata. Data is only saved in rockDataTable.
        uniAxialCompressiveStrength; %Proxyvariable for uni axial compressive strength of rock in rockdata. Data is only saved in rockDataTable.
        uniAxialEModulus; %Proxyvariable for e module of uni axial compressive strength test of rock in rockdata. Data is only saved in rockDataTable.
	end
	
	properties (SetAccess = private, GetAccess = private)
		dataTable; %Table containing all rockdata from database
	end
    
    methods
        function obj = ExperimentsSpecimenData(experimentNo)
        %The experiment number (immutable) has to be set int the constructor and can
        %not be changed later.
            obj.experimentNo = experimentNo;
        end
        
        %SETTER
        function obj = setDataAsTable(obj, dataTable)
        %Set all metadata for the experiment into the object.
        %Input parameter: table with rockData
            obj.dataTable = dataTable;
            
            obj.dataTable.Properties.VariableUnits{'height'} = 'cm';
            obj.dataTable.Properties.VariableUnits{'diameter'} = 'cm';
            obj.dataTable.Properties.VariableUnits{'massSat'} = 'g';
            obj.dataTable.Properties.VariableUnits{'massWet'} = 'g';
            obj.dataTable.Properties.VariableUnits{'massDry'} = 'g';
            obj.dataTable.Properties.VariableUnits{'densityWet'} = 'g/cm³';
            obj.dataTable.Properties.VariableUnits{'densitySat'} = 'g/cm³';
            obj.dataTable.Properties.VariableUnits{'densityDry'} = 'g/cm³';
            obj.dataTable.Properties.VariableUnits{'densityGrain'} = 'g/cm³';
            obj.dataTable.Properties.VariableUnits{'permCoeff'} = 'm/s';
            obj.dataTable.Properties.VariableUnits{'porosity'} = '-';
            obj.dataTable.Properties.VariableUnits{'voidRatio'} = '-';
            obj.dataTable.Properties.VariableUnits{'uniAxCompStrength'} = 'kN/m²';
            obj.dataTable.Properties.VariableUnits{'uniAxEModulus'} = 'kN/m²';
            
            
            disp([class(obj), ': ', 'Data set sucessfully']);
        end
        
        %GETTER
        function experimentNo = get.experimentNo(obj) 
            experimentNo = single(obj.experimentNo);
        end
        
        function specimen = get.specimen(obj) 
            specimen.value = obj.dataTable.specimenName{1};
			specimen.name = 'Specimen';
        end
        
        function rockType = get.rockType(obj) 
            rockType.value = obj.dataTable.rockName{1};
			rockType.name = 'Rockname';
        end
        
        function rockDescription = get.rockDescription(obj) 
            rockDescription.value = obj.dataTable.description{1};
			rockDescription.name = 'Rock Description';
        end
        
        function height = get.height(obj) 
            height.value = single(obj.dataTable.height);
            height.unit = obj.dataTable.Properties.VariableUnits{'height'};
			height.name = 'Probe Height';
        end
        
        function diameter = get.diameter(obj) 
            diameter.value = single(obj.dataTable.diameter);
            diameter.unit = obj.dataTable.Properties.VariableUnits{'diameter'};
			diameter.name = 'Probe Diameter';
        end
        
        function massSaturated = get.massSaturated(obj) 
            massSaturated.value = single(obj.dataTable.massSat);
            massSaturated.unit = obj.dataTable.Properties.VariableUnits{'massSat'};
			massSaturated.name = 'Probe Mass Saturated';
        end
        
        function massDry = get.massDry(obj) 
            massDry.value = single(obj.dataTable.massDry);
            massDry.unit = obj.dataTable.Properties.VariableUnits{'massDry'};
			massDry.name = 'Probe Mass Dry';
        end
        
        function massWet = get.massWet(obj) 
            massWet.value = single(obj.dataTable.massWet);
            massWet.unit = obj.dataTable.Properties.VariableUnits{'massWet'};
			massWet.name = 'Probe Mass Wet';
        end
        
        function densityWet = get.rockDensityWet(obj) 
            densityWet.value = single(obj.dataTable.densityWet);
            densityWet.unit = obj.dataTable.Properties.VariableUnits{'densityWet'};
			densityWet.name = 'Rock Density Wet';
        end
        
        function density = get.rockDensitySaturated(obj) 
            density.value = single(obj.dataTable.densitySat);
            density.unit = obj.dataTable.Properties.VariableUnits{'densitySat'};
			density.name = 'Rock Density Saturated';
        end
        
        function density = get.rockDensityDry(obj) 
            density.value = single(obj.dataTable.densityDry);
            density.unit = obj.dataTable.Properties.VariableUnits{'densityDry'};
			density.name = 'Rock Density Dry';
        end
        
        function density = get.rockDensityGrain(obj) 
            density.value = single(obj.dataTable.densityGrain);
            density.unit = obj.dataTable.Properties.VariableUnits{'densityGrain'};
			density.name = 'Rock Density Grain';
        end
        
        function densityDry = get.densityDry(obj) 
            densityDry.value = single(obj.dataTable.massWet/(obj.dataTable.height*pi*(obj.dataTable.diameter/2)^2));
            densityDry.unit = obj.dataTable.Properties.VariableUnits{'densitySat'};
			densityDry.name = 'Probe Density Dry';
        end
        
        function densitySaturated = get.densitySaturated(obj) 
            densitySaturated.value = single(obj.dataTable.massSat/(obj.dataTable.height*pi*(obj.dataTable.diameter/2)^2));
            densitySaturated.unit = obj.dataTable.Properties.VariableUnits{'densitySat'};
			densitySaturated.name = 'Probe Density Saturated';
        end
        
        function permeabilityCoefficient = get.permeabilityCoefficient(obj) 
            permeabilityCoefficient.value = single(obj.dataTable.permCoeff);
            permeabilityCoefficient.unit = obj.dataTable.Properties.VariableUnits{'permCoeff'};
			permeabilityCoefficient.name = 'Rock Permeability Coefficient';
        end
        
        function porosity = get.porosity(obj) 
            porosity.value = single(obj.dataTable.porosity);
            porosity.unit = obj.dataTable.Properties.VariableUnits{'porosity'};
			porosity.name = 'Porosity';
        end
        
        function voidRatio = get.voidRatio(obj) 
            voidRatio.value = single(obj.dataTable.voidRatio);
            voidRatio.unit = obj.dataTable.Properties.VariableUnits{'voidRatio'};
			voidRatio.name = 'Void Ratio';
        end
        
        function uniAxialCompressiveStrength = get.uniAxialCompressiveStrength(obj) 
            uniAxialCompressiveStrength.value = single(obj.dataTable.uniAxCompStrength);
            uniAxialCompressiveStrength.unit = obj.dataTable.Properties.VariableUnits{'uniAxCompStrength'};
			uniAxialCompressiveStrength.name = 'Uniaxial Compression Strength';
        end
        
        function uniAxialEModulus = get.uniAxialEModulus(obj) 
            uniAxialEModulus.value = single(obj.dataTable.uniAxEModulus);
            uniAxialEModulus.unit = obj.dataTable.Properties.VariableUnits{'uniAxEModulus'};
			uniAxialEModulus.name = 'Uniaxial E-Modulus';
		end
        
		function dataTable = getDataTable(obj)
		%Return a table containing two columns. First column contains Name and Units. Seconds column contains values. All
		%data saved in this class will be spit out.
			
			dataTable = table();
			
			
			dataTable.property = { ...
				obj.specimen.name; ...
				strcat(obj.height.name, ' [', obj.height.unit ,']'); ...
				strcat(obj.diameter.name, ' [', obj.diameter.unit ,']'); ...
				strcat(obj.massSaturated.name, ' [', obj.massSaturated.unit ,']'); ...
				strcat(obj.massWet.name, ' [', obj.massWet.unit ,']'); ...
				strcat(obj.massDry.name, ' [', obj.massDry.unit ,']'); ...
				obj.rockType.name; ...
				obj.rockDescription.name; ...
				strcat(obj.rockDensityWet.name, ' [', obj.rockDensityWet.unit ,']'); ...
				strcat(obj.rockDensitySaturated.name, ' [', obj.rockDensitySaturated.unit ,']'); ...
				strcat(obj.rockDensityDry.name, ' [', obj.rockDensityDry.unit ,']'); ...
				strcat(obj.rockDensityGrain.name, ' [', obj.rockDensityGrain.unit ,']'); ...
				strcat(obj.permeabilityCoefficient.name, ' [', obj.permeabilityCoefficient.unit ,']'); ...
				strcat(obj.porosity.name, ' [', obj.porosity.unit ,']'); ...
				strcat(obj.voidRatio.name, ' [', obj.voidRatio.unit ,']'); ...
				strcat(obj.uniAxialCompressiveStrength.name, ' [', obj.uniAxialCompressiveStrength.unit ,']'); ...
				strcat(obj.uniAxialEModulus.name, ' [', obj.uniAxialEModulus.unit ,']'); ...
				};
			
			dataTable.values = { ...
				obj.specimen.value; ...
				num2str(obj.height.value, 4); ...
				num2str(obj.diameter.value, 4); ...
				num2str(obj.massSaturated.value, 6); ...
				num2str(obj.massWet.value, 6); ...
				num2str(obj.massDry.value, 6); ...
				obj.rockType.value; ...
				obj.rockDescription.value; ...
				num2str(obj.rockDensityWet.value, 6); ...
				num2str(obj.rockDensitySaturated.value, 6); ...
				num2str(obj.rockDensityDry.value, 6); ...
				num2str(obj.rockDensityGrain.value, 6); ...
				num2str(obj.permeabilityCoefficient.value, 6); ...
				num2str(obj.porosity.value, 6); ...
				num2str(obj.voidRatio.value, 6); ...
				num2str(obj.uniAxialCompressiveStrength.value, 6); ...
				num2str(obj.uniAxialEModulus.value, 6); ...
				};
			
		end
        
    end
end