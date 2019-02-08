-- paramentros para teste
set @startDate := '2017-07-21 00:00:00';
set @endDate := '2018-06-20 00:00:00';
set @location := 418; -- location de uma us de inhambane


select *

from
	(select 	inscricao.patient_id,
    			pid.identifier as nid,
                '' as owner_name,
                concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,'')) as nome,
                concat(ifnull(pn.family_name,'')) as apelido,
                pat_details.gender as genero,
                pat_details.birthdate  as data_do_nacimento,
                DATE_FORMAT(levantamento.encounter_datetime,'%d/%m/%Y')  data_ultima_consulta,
		        DATE_FORMAT(seguimento.value_datetime,'%d/%m/%Y')  data_proxima_consulta,
                filhos.filhos,
                if( gravida_real.data_gravida is not null or gravida_real.data_gravida <> '' ,'TRUE','') as gravida,
                 'tarv' as estado_tarv  ,
                 				pat.value as telefone,
				pad3.state_province  provincia,
				pad3.county_district   distrito,
				pad3.address5  bairro,
				pad3.address1  celula,
                '0' as a_faltar
			
			
	from		
			( select patient_id,data_inicio
    from
	(	Select patient_id,min(data_inicio) data_inicio
			   
		from
				(	Select 	p.patient_id,min(e.encounter_datetime) data_inicio
					from 	patient p 
							inner join encounter e on p.patient_id=e.patient_id	
							inner join obs o on o.encounter_id=e.encounter_id
					where 	e.voided=0 and o.voided=0 and p.voided=0 and 
							e.encounter_type in (18,6,9) and o.concept_id=1255 and o.value_coded=1256 and 
							e.encounter_datetime<=@endDate and e.location_id=@location
					group by p.patient_id
			
					union
			
					Select 	p.patient_id,min(value_datetime) data_inicio
					from 	patient p
							inner join encounter e on p.patient_id=e.patient_id
							inner join obs o on e.encounter_id=o.encounter_id
					where 	p.voided=0 and e.voided=0 and o.voided=0 and e.encounter_type in (18,6,9) and 
							o.concept_id=1190 and o.value_datetime is not null and 
							o.value_datetime<=@endDate and e.location_id=@location
					group by p.patient_id

					union

					select 	pg.patient_id,date_enrolled data_inicio
					from 	patient p inner join patient_program pg on p.patient_id=pg.patient_id
					where 	pg.voided=0 and p.voided=0 and program_id=2 and date_enrolled<=@endDate and location_id=@location
					
					union
					
					
				  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio 
				  FROM 		patient p
							inner join encounter e on p.patient_id=e.patient_id
				  WHERE		p.voided=0 and e.encounter_type=18 AND e.voided=0 and e.encounter_datetime<=@endDate and e.location_id=@location
				  GROUP BY 	p.patient_id			
					
					
				) inicio
			group by patient_id	

	)inicio1

where data_inicio between @startDate and @endDate
) 		 inscricao
			left join 
			(	select pad1.*
				from person_address pad1
				inner join 
				(
					select person_id,min(person_address_id) id 
					from person_address
					where voided=0
					group by person_id
				) pad2
				where pad1.person_id=pad2.person_id and pad1.person_address_id=pad2.id
			) pad3 on pad3.person_id=inscricao.patient_id				
			left join 			
			(	select pn1.*
				from person_name pn1
				inner join 
				(
					select person_id,min(person_name_id) id 
					from person_name
					where voided=0
					group by person_id
				) pn2
				where pn1.person_id=pn2.person_id and pn1.person_name_id=pn2.id
			) pn on pn.person_id=inscricao.patient_id			
			left join
			(    select pid1.*
					from patient_identifier pid1
					inner join
									(
													select patient_id,min(patient_identifier_id) id
													from patient_identifier
													where voided=0
													group by patient_id
									) pid2
					where pid1.patient_id=pid2.patient_id and pid1.patient_identifier_id=pid2.id
			) pid on pid.patient_id=inscricao.patient_id
             left join
             (   select ptd.* 
             
			       from 	person ptd			
					
					inner join patient pe on pe.patient_id=ptd.person_id			
			group by patient_id
             ) pat_details on pat_details.person_id = inscricao.patient_id
             left join 
(	select person_id,max(value_numeric) filhos
	from obs
	where voided=0 and concept_id=5573 and location_id=@location and obs_datetime<@endDate
	group by person_id
) filhos on filhos.person_id=inscricao.patient_id
  left join
  (   select patient_id,max(data_gravida) as data_gravida
			from
				(	Select p.patient_id,max(obs_datetime) data_gravida
					from    patient p 
							inner join encounter e on p.patient_id=e.patient_id
							inner join obs o on e.encounter_id=o.encounter_id
					where   p.voided=0 and e.voided=0 and o.voided=0 and 
							((concept_id=1982 and value_coded=44) or concept_id=1279) and 
							e.encounter_type in (5,6) and o.obs_datetime between date_add(@endDate, interval -1 YEAR) and @endDate and 
							e.location_id=@location
					group by p.patient_id
					
					union
					
					select 	pp.patient_id,pp.date_enrolled as data_gravida
					from    patient_program pp 
					where   pp.program_id=8 and pp.voided=0 and 
							pp.date_enrolled between @startDate and @endDate and pp.location_id=@location
					union
					
					Select 	p.patient_id,max(e.encounter_datetime) data_gravida
					from 	patient p inner join encounter e on p.patient_id=e.patient_id
							inner join obs o on e.encounter_id=o.encounter_id
					where 	p.voided=0 and e.voided=0 and o.voided=0 and concept_id=1600 and 
							e.encounter_type in (5,6) and e.encounter_datetime between date_add(@endDate, interval -1 YEAR) and @endDate and e.location_id=@location
					group by p.patient_id
					
				)gravida
			group by patient_id
	) gravida_real on gravida_real.patient_id =inscricao.patient_id
        
left join 
(	Select 	prox_levantamento.patient_id,prox_levantamento.encounter_datetime,o.value_datetime,e.location_id
	from
		(	select 	p.patient_id,max(encounter_datetime) as encounter_datetime
			from 	encounter e 
					inner join patient p on p.patient_id=e.patient_id 		
			where 	e.voided=0 and p.voided=0 and e.encounter_type=18 and e.location_id=@location 
			group by p.patient_id
		) prox_levantamento
		inner join encounter e on e.patient_id=prox_levantamento.patient_id
		inner join obs o on o.encounter_id=e.encounter_id			
	where o.concept_id=5096 and o.voided=0 and e.encounter_datetime=prox_levantamento.encounter_datetime and 
			e.encounter_type=18 and e.location_id=@location
) levantamento on levantamento.patient_id=inscricao.patient_id

left join 

(	Select 	ultimavisita.patient_id,ultimavisita.encounter_datetime,o.value_datetime,e.location_id
	from
		(	select 	p.patient_id,max(encounter_datetime) as encounter_datetime
			from 	encounter e 
					inner join patient p on p.patient_id=e.patient_id 		
			where 	e.voided=0 and p.voided=0 and e.encounter_type in (6,9) and e.location_id=@location and e.encounter_datetime<=@endDate
			group by p.patient_id
		) ultimavisita
		inner join encounter e on e.patient_id=ultimavisita.patient_id
		inner join obs o on o.encounter_id=e.encounter_id			
	where o.concept_id=1410 and o.voided=0 and e.encounter_datetime=ultimavisita.encounter_datetime and 
			e.encounter_type in (6,9) and e.location_id=@location
) seguimento on seguimento.patient_id=inscricao.patient_id

			left join 
			(	select patient_id,min(encounter_datetime) data_seguimento
				from encounter
				where voided=0 and encounter_type in (6,9) and encounter_datetime between @startDate and @endDate
				group by patient_id
			) seguimento_t on seguimento_t.patient_id=inscricao.patient_id
			left join person_attribute pat on pat.person_id=inscricao.patient_id and pat.person_attribute_type_id=9 and pat.value is not null and pat.value<>'' and pat.voided=0
			left join
			(	select 	p.patient_id,min(encounter_datetime) as data_aceita
				from 	patient p
						inner join encounter e on p.patient_id=e.patient_id
						inner join obs o on o.encounter_id=e.encounter_id
				where 	encounter_type in (34,35) and e.voided=0 and
						encounter_datetime<=@endDate and e.location_id=@location
						and p.voided=0 and o.voided=0 and o.concept_id=6309 and o.value_coded=6307
				group by patient_id
			) contacto on contacto.patient_id=inscricao.patient_id
	)inscritos where 	
 inscritos.patient_id not in 
	(
		select 	pg.patient_id
		from 	patient p 
				inner join patient_program pg on p.patient_id=pg.patient_id
				inner join patient_state ps on pg.patient_program_id=ps.patient_program_id
		where 	pg.voided=0 and ps.voided=0 and p.voided=0 and 
				pg.program_id=2 and ps.state=29 and ps.start_date=pg.date_enrolled and 
				ps.start_date between @startDate and @endDate and location_id=@location
	)
group by patient_id

union all


select * 
from
(select 	max_frida.patient_id,
		pid.identifier as NID,
      '' as owner_name,
      concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,''))  nome,
      concat(ifnull(pn.family_name,'')) as apelido,
       	p.gender as genero,
        p.birthdate  as data_do_nacimento,
		 DATE_FORMAT(encounter_datetime,'%d/%m/%Y')   data_ultima_consulta,
		 DATE_FORMAT(o.value_datetime,'%d/%m/%Y')  data_proxima_consulta,
         filhos.filhos,
         '' as gravida,
                 'tarv' as estado_tarv  ,
                 	pat.value as telefone,
		pad3.county_district  provincia,
		pad3.address2  distrito,
		pad3.address5  bairro,
		pad3.address1  celula,
		'1' as a_faltar
from
		(	Select 	p.patient_id,max(encounter_datetime) encounter_datetime
			from 	patient p 
					inner join encounter e on e.patient_id=p.patient_id
			where 	p.voided=0 and e.voided=0 and e.encounter_type=18 and 
					e.location_id=@location and e.encounter_datetime<=@endDate
			group by p.patient_id
		) max_frida 
		inner join obs o on o.person_id=max_frida.patient_id
		inner join person p on p.person_id=max_frida.patient_id
		left join 
		(	select pad1.*
			from person_address pad1
			inner join 
			(
				select person_id,min(person_address_id) id 
				from person_address
				where voided=0
				group by person_id
			) pad2
			where pad1.person_id=pad2.person_id and pad1.person_address_id=pad2.id
		) pad3 on pad3.person_id=max_frida.patient_id				
		left join 			
		(	select pn1.*
			from person_name pn1
			inner join 
			(
				select person_id,min(person_name_id) id 
				from person_name
				where voided=0
				group by person_id
			) pn2
			where pn1.person_id=pn2.person_id and pn1.person_name_id=pn2.id
		) pn on pn.person_id=max_frida.patient_id			
		left join
		(   select pid1.*
			from patient_identifier pid1
			inner join
			(
				select patient_id,min(patient_identifier_id) id
				from patient_identifier
				where voided=0
				group by patient_id
			) pid2
			where pid1.patient_id=pid2.patient_id and pid1.patient_identifier_id=pid2.id
		) pid on pid.patient_id=max_frida.patient_id
		left join person_attribute pat on pat.person_id=max_frida.patient_id and pat.person_attribute_type_id=9 and pat.value is not null and pat.value<>'' and pat.voided=0
             left join 
(	select person_id,max(value_numeric) filhos
	from obs
	where voided=0 and concept_id=5573 and location_id=@location and obs_datetime<@endDate
	group by person_id
) filhos on filhos.person_id=max_frida.patient_id

where 	max_frida.encounter_datetime=o.obs_datetime and o.voided=0 and o.concept_id=5096 and o.location_id=@location and 
		max_frida.patient_id not in 
		(
			select 	pg.patient_id
			from 	patient p 
					inner join patient_program pg on p.patient_id=pg.patient_id
					inner join patient_state ps on pg.patient_program_id=ps.patient_program_id
			where 	pg.voided=0 and ps.voided=0 and p.voided=0 and 
					pg.program_id=2 and ps.state in (7,8,9,10) and ps.end_date is null and 
					ps.start_date<=@endDate and location_id=@location								
		)
		and  datediff(@endDate,o.value_datetime) between 4 and 11
   
) faltoso 
group by patient_id
