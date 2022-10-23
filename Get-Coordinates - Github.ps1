<#
.SYNOPSIS
Displays information about a certain place or address
.DESCRIPTION
Tries to find the provided place/address on Google Maps and display it's information
.INPUTS
System.String. Get-Coordinates accepts a string to search for as an address or a place
.OUTPUTS
System.String. Outputs information related to the specified address/place 
.EXAMPLE
C:\PS> Get-Coordinates "Heathrow Airport"
Country:	United Kingdom
Latitude:	51.4700223
Longitude:	-0.4542955
.EXAMPLE
C:\PS> Get-Coordinates "Heathrow Airport" -FullDes
Country:		United Kingdom
City:			Longford
Full Address:	Heathrow Airport (LHR), Longford TW6, UK
Postal Code:	TW6
Latitude:		51.4700223
Longitude:		-0.4542955
.EXAMPLE
C:\PS> Get-Coordinates "Heathrow Airport" -OutputAsObject
Longtitude   Latitude
----------   --------
-0.4542955 51.4700223
.EXAMPLE
C:\PS> Get-Coordinates "1600 Pennsylvania Avenue NW" -FullDes
Country:		United States
City:			Washington
Full Address:	1600 Pennsylvania Avenue NW, Washington, DC 20500, USA
Postal Code:	20500
Latitude:		38.8976633
Longitude:		-77.03657389999999
#>

function Get-Coordinates
{
  [CmdletBinding()] 
  Param(
    [Parameter(Mandatory=$true)][String][ValidateNotNullOrEmpty] $Address,
    [Parameter(Mandatory=$true)][String][ValidateNotNullOrEmpty] $API_Key,
    #Mandatory - privalomas parametras (adresas kurio ieskos)
    #Position - is kurios pozicijos ims (nulines/pirmos ir galima ivesti adresa nenurodant paramentro vardo (-Address))
    #ValueFromPipeline - leidzia kviesti funkcija pipeline principu (t.y. "Sauletekio al. 11 | Get-Coordinates")
    [Parameter()] [Switch] $FullDes,
    [Parameter()] [Switch] $OutputAsObject
  )

  Begin{
        If(!$API_Key) #Patikrina, ar yra API raktas
        {
            Throw "Reikia prideti API rakta"
        }
    }
   Process{
        ForEach ($item in $Address){
            Try{
                $WebAddress = $Item.replace(" ","+") #pakeiciamas ivesto adreso string tarpai i +, nes tarpu negali buti ieskant (pvz. https://www.google.com/maps/place/Saul%C4%97tekio+al.+11)

                $JsonReturn = Invoke-WebRequest "https://maps.googleapis.com/maps/api/geocode/json?address=$WebAddress&key=$API_Key" -ErrorVariable ErrorMessage
                #Invoke-WebRequest siuncia uzklausa google maps atitinkamu adresu, naujant pateikta gatves adresa ($WebAddress), kurio norima ieskoti bei API rakta ($API_Key), kad leistu naudotis servisu ne per narsykle
                #Gaunami duomenys JSON formatu
                #ErrorVariable isaugo bet kokia gauta klaida ErrorVMessage

                $Results = $JsonReturn.Content | ConvertFrom-Json | select Results -ExpandProperty Results
                #Konvertuoja ir issaugo JSON dokumento "Results" masyvo/array duomenis

                $Status = $JsonReturn.Content | ConvertFrom-Json | select Status -ExpandProperty Status
                #Konvertuoja ir issaugo JSON dokumento "Status" kintamojo duomenis

                if ($Status -eq "OK"){
                        $Country = ($Results.address_components | Where {$_.types -like "*Country*"}).Long_name
                        $lat = $Results.geometry.location.lat
                        $lng = $Results.geometry.location.lng
                    if ($FullDes){
                        $FullAddress = $Results.formatted_address
                        $City = ($Results.address_components | Where {$_.types -like "*Locality*"}).Long_name
                        $PostalCode = ($Results.address_components | Where {$_.types -like "*Postal_code*"}).Long_name
                        "Country:`t`t$($Country)`nCity:`t`t`t$($City)`nFull Address:`t$($FullAddress)`nPostal Code:`t$($PostalCode)`nLatitude:`t`t$($lat)`nLongitude:`t`t$($lng)`n"
                    }
                    elseif ($OutputAsObject){
                        New-Object -TypeName PSObject -Property @{Latitude = $lat; Longtitude = $lng}
                    }
                    else{
                       "Country:`t$($Country)`nLatitude:`t$($lat)`nLongitude:`t$($lng)`n"
                    }
                }
                else{
                    "Ivyko klaida ieskant duoto objekto/adreso. Error: $($Status)"
                }
            }
            Catch{
                "Problemos su google servisu. Error: $($ErrorMessage.Message) "
            }
        }

   }

}
