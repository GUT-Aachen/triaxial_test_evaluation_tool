# Triaxial Test Evaluation Tool
> With this evaluation tool you can check and interpret the results of a modified <a href="https://en.wikipedia.org/wiki/Triaxial_shear_test" target="_blank">`geotechnical triaxial test`</a>. With this aperature it is possible to confine a probe, rise the axial stress and measure the permeability of the probe at all stages. The tool was developed as part of a joint project called MERID (Microstructural Influence on Reservoir Integrity at Variable Hydromechanical Conditions) funded by the German Federal Ministry of Education and Research as part of GEO:N Project ([Geoforschung für Nachhaltigkeit](https://www.bmbf.de/de/geoforschung-2398.html)) to evaluate the results of a special assembled large triaxial cell. This tool consists of a backend and a frontend both assembled in MathWorks Matlab. The backend creates a connection to a MySQL-Database where all experiments results are stored.

[![License: CC BY 3.0](https://img.shields.io/badge/License-CC%20BY%203.0-lightgrey.svg)](https://creativecommons.org/licenses/by/3.0/de/deed.en)

---

## Features

### Frontend (GUI)
 - List and overview all experiments in database
 - Keep rock/soil parameters always in view
 - Check experiment description and additional comments
 - Get an overview of important parameters and their connection
 - Show experiments timelog related to experiments data
 - Change integration timestep for permeability calculation
 - Plot graphs with variable x-axis and two possible y-axis
 - Compare to different/independent experiments
 - Export graphs easiely as raster graphics (1200 DPI) or vector graphics


### Backend
 - Class oriented programming in matlab
 - Connection to MySQL database
 - Interface between frontend (GUI) and MySQL database
 - Seperated classes for handling experiments meta data `ExperimentsMetaData`, meassured values `ExperimentsData`, rock/soil related data `ExperimentsSpecimenData`, MySQL database connection `MeridDB`, interface to frontend (GUI) `TriaxTestHandler`
 - Measured data cleansing like filtering NaN values
 - Calculating permeability and permeability coefficient according to fluid (water) properties with help of isantosruiz <a href="https://github.com/isantosruiz/water-properties" target="_blank">`water-properties`</a> repository.
 
---

## Setup
Under construction

---

## Usage
Under construction

---

## FAQ
Under construction

---

## Support
Reach out to me at one of the following places!

- Website at <a href="http://www.geotechnik.rwth-aachen.de/index.php?section=Biebricher_en" target="_blank">`www.geotechnik.rwth-aachen.de`</a>

---

## License
[![License: CC BY 3.0](https://img.shields.io/badge/License-CC%20BY%203.0-lightgrey.svg)](https://creativecommons.org/licenses/by/3.0/de/deed.en)

This tool can be shared and adapted used under **Creative Common Attribution 3.0** license: You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
