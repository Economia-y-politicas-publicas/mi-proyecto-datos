clear all
*profesor solo hay que cambiar esta linea
cd "C:\Users\juanm\Desktop\manim\quarto-template\imagenes\consumo"
use cuentasnacionales
set more off
gen tiempo = tq(1996q1) + _n - 1
format tiempo %tq
tsset tiempo
rename consumototal             ct
rename consumodehogareseipsfl   ch
rename bienesdurables           bd
rename bienesnodurables         bnd
rename servicios                srv
rename consumogobierno          cg
rename Formaciónbrutadecapitalfijo fbkf
rename Construcciónyotrasobras  cons
rename maquinariayequipo        mye
rename exportacionesdebienesyservicios  x
rename importacionesdebienesyservicios  m
rename productointernobruto     pib
local vars ct ch bd bnd srv cg fbkf cons mye x m pib
*logs
foreach v of local vars {
    gen l`v' = ln(`v')
    label variable l`v' "Log(`v')"
}
*ciclos hp
foreach v of local vars {
    tsfilter hp cyc_`v' = l`v', smooth(1600) trend(trend_`v')
    label variable cyc_`v' "Ciclo HP: `v'"
    label variable trend_`v' "Tendencia HP: `v'"
}
*preparar tablita
quietly sum cyc_pib
local sd_pib = r(sd)
local nvars : word count `vars'
matrix R = J(`nvars', 4, .)
matrix rownames R = `vars'
matrix colnames R = "SD" "SD_SDpib" "AC1" "CorrPIB"
local i = 1
*col 1 sd, col 2 sd/sdpib , col 3 autocorr, col 4 corr instantanea pib
foreach v of local vars {
    quietly sum cyc_`v'
    local sd_v = r(sd)
    matrix R[`i', 1] = `sd_v'
    matrix R[`i', 2] = `sd_v' / `sd_pib'
    quietly corr cyc_`v' L.cyc_`v'
    matrix R[`i', 3] = r(rho)
    quietly corr cyc_`v' cyc_pib
    matrix R[`i', 4] = r(rho)
    local i = `i' + 1
}

*tablita en consola
di _newline
di "=================================================================="
di "   PROPIEDADES DEL CICLO ECONÓMICO (Filtro HP, lambda=1600)"
di "=================================================================="
di "%-32s %10s  %10s  %8s  %10s" "Variable" "SD" "SD/SD(PIB)" "AC(1)" "Corr(PIB)"
di "--------------------------------------------------------------------------"
local i = 1
foreach v of local vars {
    local sd     : display %10.4f R[`i', 1]
    local sdrel  : display %10.4f R[`i', 2]
    local ac1    : display %8.4f  R[`i', 3]
    local corr   : display %10.4f R[`i', 4]
    local i = `i' + 1
}
di "=========================================================================="


preserve
clear
svmat R, names(col)
* nombres sin tildes ni caracteres especiales para evitar corrupcion
gen Variable = ""
replace Variable = "Consumo Total"             in 1
replace Variable = "Consumo Hogares e IPSFL"   in 2
replace Variable = "Bienes Durables"           in 3
replace Variable = "Bienes No Durables"        in 4
replace Variable = "Servicios"                 in 5
replace Variable = "Consumo Gobierno"          in 6
replace Variable = "FBCF Total"                in 7
replace Variable = "Construccion y Otras Obras" in 8
replace Variable = "Maquinaria y Equipo"       in 9
replace Variable = "Exportaciones B&S"         in 10
replace Variable = "Importaciones B&S"         in 11
replace Variable = "PIB"                       in 12
order Variable SD SD_SDpib AC1 CorrPIB
rename SD_SDpib SD_sobre_SD_PIB
rename CorrPIB  Corr_PIB
export delimited using "tabla_ciclo.csv", replace
restore
di _newline ">> Tabla exportada a: tabla_ciclo.csv"

twoway ///
    (line cyc_pib tiempo, lcolor(navy) lwidth(medthick)) ///
    (line cyc_ct  tiempo, lcolor(red)  lpattern(dash)), ///
    title("Componente Cíclico: PIB y Consumo Total") ///
    subtitle("Filtro Hodrick-Prescott (λ=1600)") ///
    ytitle("Desviación log de tendencia") xtitle("Trimestre") ///
    legend(pos(7) col(2) ring (0) label(1 "PIB") label(2 "Consumo Total"))
*cyc_ch cyc_bd cyc_bnd cyc_srv cyc_cg cyc_fbkf cyc_cons cyc_mye cyc_x cyc_m cyc_pib
graph save "consumototal", replace		
	
twoway ///
    (line cyc_pib tiempo, lcolor(navy) lwidth(medthick)) ///
    (line cyc_ch  tiempo, lcolor(red)  lpattern(dash)), ///
    title("Componente Cíclico: PIB y Consumo Hogares e IPSFL") ///
    subtitle("Filtro Hodrick-Prescott (λ=1600)") ///
    ytitle("Desviación log de tendencia") xtitle("Trimestre") ///
    legend(label(1 "PIB") label(2 "Consumo Hogares e IPSFL"))	

graph save "consumohogar", replace	
twoway ///
    (line cyc_pib tiempo, lcolor(navy) lwidth(medthick)) ///
    (line cyc_bd  tiempo, lcolor(red)  lpattern(dash)), ///
    title("Componente Cíclico: PIB y Bienes Duranbles") ///
    subtitle("Filtro Hodrick-Prescott (λ=1600)") ///
    ytitle("Desviación log de tendencia") xtitle("Trimestre") ///
    legend(label(1 "PIB") label(2 "Bienes Duranbles"))	
		
twoway ///
    (line cyc_pib tiempo, lcolor(navy) lwidth(medthick)) ///
    (line cyc_bnd  tiempo, lcolor(red)  lpattern(dash)), ///
    title("Componente Cíclico: PIB y Bienes No Duranbles") ///
    subtitle("Filtro Hodrick-Prescott (λ=1600)") ///
    ytitle("Desviación log de tendencia") xtitle("Trimestre") ///
    legend(label(1 "PIB") label(2 "Bienes No Duranbles"))		
	
twoway ///
    (line cyc_pib tiempo, lcolor(navy) lwidth(medthick)) ///
    (line cyc_srv  tiempo, lcolor(red)  lpattern(dash)), ///
    title("Componente Cíclico: PIB y Servicios") ///
    subtitle("Filtro Hodrick-Prescott (λ=1600)") ///
    ytitle("Desviación log de tendencia") xtitle("Trimestre") ///
    legend(label(1 "PIB") label(2 "Servicios"))		

*gob es super ruidoso
twoway ///
    (line cyc_pib tiempo, lcolor(navy) lwidth(medthick)) ///
    (line cyc_cg  tiempo, lcolor(red)  lpattern(dash)), ///
    title("Componente Cíclico: PIB y Gobierno") ///
    subtitle("Filtro Hodrick-Prescott (λ=1600)") ///
    ytitle("Desviación log de tendencia") xtitle("Trimestre") ///
    legend(pos(7) col(2) ring (0) label(1 "PIB") label(2 "Gobierno"))		
graph save "gobierno", replace			
twoway ///
    (line cyc_pib tiempo, lcolor(navy) lwidth(medthick)) ///
    (line cyc_fbkf  tiempo, lcolor(red)  lpattern(dash)), ///
    title("Componente Cíclico: PIB e Inversión (FBCF) ") ///
    subtitle("Filtro Hodrick-Prescott (λ=1600)") ///
    ytitle("Desviación log de tendencia") xtitle("Trimestre") ///
    legend(pos(7) col(2) ring (0) label(1 "PIB") label(2 "Inversión (FBCF)"))	
	
graph save "inversion", replace				
twoway ///
    (line cyc_pib tiempo, lcolor(navy) lwidth(medthick)) ///
    (line cyc_cons  tiempo, lcolor(red)  lpattern(dash)), ///
    title("Componente Cíclico: PIB y Construcción y otras obras") ///
    subtitle("Filtro Hodrick-Prescott (λ=1600)") ///
    ytitle("Desviación log de tendencia") xtitle("Trimestre") ///
    legend(label(1 "PIB") label(2 "Construcción y otras obras"))		
					
twoway ///
    (line cyc_pib tiempo, lcolor(navy) lwidth(medthick)) ///
    (line cyc_mye  tiempo, lcolor(red)  lpattern(dash)), ///
    title("Componente Cíclico: PIB y Maquinaria y equipo") ///
    subtitle("Filtro Hodrick-Prescott (λ=1600)") ///
    ytitle("Desviación log de tendencia") xtitle("Trimestre") ///
    legend(label(1 "PIB") label(2 "Maquinaria y equipo"))		
	
twoway ///
    (line cyc_pib tiempo, lcolor(navy) lwidth(medthick)) ///
    (line cyc_x  tiempo, lcolor(red)  lpattern(dash)), ///
    title("Componente Cíclico: PIB y Exportaciones") ///
    subtitle("Filtro Hodrick-Prescott (λ=1600)") ///
    ytitle("Desviación log de tendencia") xtitle("Trimestre") ///
    legend(label(1 "PIB") label(2 "Exportaciones"))		
	
twoway ///
    (line cyc_pib tiempo, lcolor(navy) lwidth(medthick)) ///
    (line cyc_m  tiempo, lcolor(red)  lpattern(dash)), ///
    title("Componente Cíclico: PIB y Importaciones") ///
    subtitle("Filtro Hodrick-Prescott (λ=1600)") ///
    ytitle("Desviación log de tendencia") xtitle("Trimestre") ///
    legend(label(1 "PIB") label(2 "Importaciones"))		

*editar el resto en editor
graph combine "consumototal" "inversion" "gobierno", ///
    cols(3) rows(1)	ycommon  title("Componente Cíclico: PIB, Consumo, Inversión y Gobierno") ///
    subtitle("Filtro Hodrick-Prescott (λ=1600)") 
	
	
