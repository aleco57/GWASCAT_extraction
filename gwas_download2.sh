#!/bin/bash

for pub in #add in pubmedids here
do

  #Make directory
  mkdir ${pub}_sumstat
  cd ${pub}_sumstat || exit 1

  # Set the PubMed ID of interest
  pubmed_id="$pub"

  # Set the base URL for the API
  base_url="https://www.ebi.ac.uk/gwas/rest/api/"

  # Set the endpoint for the studies API
  studies_endpoint="studies/search/findByPublicationIdPubmedId"

  # Set the query parameters
  params="pubmedId=${pubmed_id}&size=1000"  # set a high value to retrieve all associated studies

  # Send the request to the API and extract the study data
  curl -s "${base_url}${studies_endpoint}?${params}" | jq -r '.["_embedded"]["studies"][] | [.accessionId, .diseaseTrait.trait] | @tsv' > "${pubmed_id}_idpheno.tsv"

#Now lets use the GCST numbers to extract our summary statistics of interest
  # Extract the first column from the TSV file and turn it into a list
  string_list=$(cut -f 1 "${pubmed_id}_idpheno.tsv" | tail -n +2 | tr '\n' ' ')

  # Set the base URL for the API
  base_url_gwas="http://ftp.ebi.ac.uk/pub/databases/gwas/summary_statistics/"

  #Set the start size
  start="GCST90000001-GCST90001000/"
  # Set the bin size
  bin_size=1000

  for id in $string_list
  do

    #Remove the GCST from the id
    number="${id#GCST}"

    # Calculate the bin number
    bin_number=$(( ($number - 1) / $bin_size ))

    range="GCST$(( $bin_number * $bin_size + 1 ))-GCST$(( ($bin_number + 1) * $bin_size ))/"
    
    file_name=$(curl -s ${base_url_gwas}${range}${id}/harmonised/md5sum.txt | grep "\.h" | cut -d " " -f 2)

    wget ${base_url_gwas}${range}${id}/harmonised/${file_name}

  done

  cd ..

done

