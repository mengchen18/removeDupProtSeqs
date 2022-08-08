FROM rocker/shiny:4.2.1

RUN mkdir /home/shiny/projects \
	&& mkdir /home/shiny/app 

RUN R -e "install.packages(c('seqinr', 'fastmatch', 'shinyFiles', 'DT', 'shinybusy'))"
RUN wget -O /home/shiny/app/app.R https://raw.githubusercontent.com/mengchen18/removeDupProtSeqs/main/app.R

CMD ["R", "-e", "shiny::runApp(file.path('/home/shiny/app', 'app.R'), host = '0.0.0.0', port = 3838)"]
