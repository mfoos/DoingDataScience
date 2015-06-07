-- VETERINARY HOSPITAL DATABASE CREATION QUERIES --
CREATE TABLE breedissues
(
  breedspecies_id serial NOT NULL,
  health_issue_desc character varying(100) NOT NULL,
  CONSTRAINT breedissues_pkey PRIMARY KEY (breedspecies_id, health_issue_desc)
);

copy breedissues (health_issue_desc)
from '/Users/Shared/breedissue.csv'
with CSV Header;
--============================================
CREATE TABLE diagnosticlookup
(
  diagnosticlookup_id serial NOT NULL,
  diagnosisname character varying(50) NOT NULL,
  CONSTRAINT diagnosticlookup_pkey PRIMARY KEY (diagnosticlookup_id)
);
 
copy diagnosticlookup (diagnosisname)
from '/Users/Shared/diagnosislookup.csv'
with CSV Header;
--============================================
CREATE TABLE breedspecies
(
  breedname character varying(50) NOT NULL,
  speciesname character varying(50) NOT NULL,
  generictype character varying(15) NOT NULL,
  avg_wt_kg integer,
  life_exp_yrs integer,
  breedspecies_id serial NOT NULL,
  CONSTRAINT breedspecies_pkey PRIMARY KEY (breedspecies_id)
);
 
copy breedspecies (breedname, speciesname, generictype, avg_wt_kg, life_exp_yrs)
from '/Users/Shared/breedspecies.csv'
with CSV Header;
--============================================
CREATE TEMPORARY TABLE pet_name_vals
(
  pet_id integer NOT NULL,
  petname character varying(30) NOT NULL
);

copy pet_name_vals (pet_id, petname)
from '/Users/Shared/petnamevals.csv'
with CSV Header;
--============================================
create table pet as

select tmp.* from (

with
DOB_range as
(select now()::date - generate_series(0,3650) as DOB, generate_series(1, 3651) as DOB_id),

weight_range as
(select round(random()*30+.5) as weight, generate_series(1, 30) as weight_id),

join_breed_nums as
(select generate_series(0, 25) as JBN),

pets_with_random_numbers as
(select pnv.pet_id, pnv.petname,
round(random()*25+.5) as species_random_num,
round(random()*3651+.5) as DOB_random_number,
round(random()*30+.5) as weight_random_number
from pet_name_vals pnv
order by pnv.pet_id
)

select pet_id, petname, breedspecies_id, weight, DOB
from pets_with_random_numbers
join DOB_range db
on DOB_random_number = db.DOB_id
join weight_range wr
on weight_random_number = wr.weight_id
join breedspecies bs
on species_random_num = bs.breedspecies_id) tmp;

ALTER TABLE pet ADD PRIMARY KEY (pet_id);
ALTER TABLE pet ADD FOREIGN KEY (breedspecies_id) references breedspecies;
ALTER TABLE pet ALTER COLUMN petname SET NOT NULL;
ALTER TABLE pet ALTER COLUMN weight SET NOT NULL;
--============================================
create table insprovider
(insureprov_id serial NOT NULL,
 insurename character varying(25) NOT NULL,
 primary key (insureprov_id)
);

Insert into InsProvider
	(insureprov_id,insurename)
Values
(1,'pet-protect'),
(2,'pet-rx'),
(3,'healthy-pet'),
(4,'perfect-paws'),
(5,'paws-for-thought'),
(6,'pet-insure'),
(7,'furry-friends'),
(8,'pet-health'),
(9,'two-by-two'),
(10,'claws-claims');
--============================================
CREATE TABLE owner
(
  owner_id serial NOT NULL,
  firstname character varying(20) NOT NULL,
  lastname character varying(20) NOT NULL,
  street_ad character varying(50),
  city character varying(20),
  state character(2) NOT NULL,
  phone character varying(50) NOT NULL,
  zip character(5) NOT NULL,
  credit_card_no character(16),
  cc_exp date,
  insureprov_id integer,
  CONSTRAINT owner_pkey PRIMARY KEY (owner_id)
);

--select firstname, initcap(lastname), state, zip, phone, creditcard as credit_card_no, --creditcardexpdate as cc_exp
--from customers
--where state = 'MA';
--exported from dvdsales

copy owner (firstname, lastname, state, zip, phone, credit_card_no, cc_exp)
from '/Users/Shared/dvdsalescust.csv'
with CSV Header;

update owner 
set street_ad =
(round(random()*2000)::varchar||' '||'Main')
where owner_id % 5 = 1;

update owner 
set street_ad =
(round(random()*2000)::varchar||' '||'Walnut')
where owner_id % 5 = 2;

update owner 
set street_ad =
(round(random()*2000)::varchar||' '||'Maple')
where owner_id % 5 = 3;

update owner 
set street_ad =
(round(random()*2000)::varchar||' '||'Willow')
where street_ad is null;

update owner
set insureprov_id = round(random()*10+.5);

create temporary table matowns (
town_id serial,
town character varying(50)
);

copy matowns (town)
from '/Users/Shared/matowns.csv'
with CSV Header;

with owner_with_random_numbers as
(select o.owner_id as owner_id,
round(random()*380+.5) as owner_rand
from owner o)

update owner 
set city =
(select mt.town
from matowns mt
join owner_with_random_numbers owrn
on mt.town_id = owrn.owner_rand
where owrn.owner_id = owner.owner_id);

ALTER TABLE owner ADD FOREIGN KEY (insureprov_id) references insprovider;
ALTER TABLE owner ALTER COLUMN street_ad SET NOT NULL;
ALTER TABLE owner ALTER COLUMN city SET NOT NULL;
--============================================
create temporary table med_driver (
med_id serial,
coveredby character varying (10),
medname character varying(50),
manufacturer character varying(50),
use_text character varying(200),
warn_text character varying(200),
units character varying(10)
);

copy med_driver (coveredby, medname, manufacturer, use_text, warn_text, units)
from '/Users/Shared/mednames.csv'
with CSV Header;

create table medication as

select tmp.* from (

with
covered_range as
(select md.coveredby as coveredby,
md.med_id
from med_driver md
where md.coveredby is not null),

manuf_range as
(select md.manufacturer as manufacturer,
md.med_id
from med_driver md
where md.manufacturer is not null),

use_range as
(select md.use_text as use_text,
md.med_id
from med_driver md
where md.use_text is not null),

warn_range as
(select md.warn_text as warn_text,
md.med_id
from med_driver md
where md.warn_text is not null),

units_range as
(select md.units as units,
md.med_id
from med_driver md
where md.units is not null),

meds_with_random_numbers as
(select md.med_id, md.medname,
round(random()*2+.5) as covered_rn,
round(random()*4+.5) as manuf_rn,
round(random()*5+.5) as use_rn,
round(random()*4+.5) as warn_rn,
round(random()*5+.5) as units_rn
from med_driver md
order by md.med_id
)

select mwrn.med_id,
 cr.coveredby, 
 mwrn.medname, 
 mr.manufacturer, 
 ur.use_text, 
 wr.warn_text,
 round(random()*6+.5) as perkg_dose, 
 unr.units,
 round(random()*100+.5)::decimal(5,2) as dose_cost
from meds_with_random_numbers mwrn
join covered_range cr
on covered_rn = cr.med_id
join manuf_range mr
on manuf_rn = mr.med_id
join use_range ur
on use_rn = ur.med_id
join warn_range wr
on warn_rn = wr.med_id
join units_range unr
on units_rn = unr.med_id
join med_driver md
on mwrn.med_id = md.med_id
) tmp;

ALTER TABLE medication ADD PRIMARY KEY (med_id);
ALTER TABLE medication ALTER COLUMN coveredby SET NOT NULL;
ALTER TABLE medication ALTER COLUMN medname SET NOT NULL;
ALTER TABLE medication ALTER COLUMN manufacturer SET NOT NULL;
ALTER TABLE medication ALTER COLUMN perkg_dose SET NOT NULL;
ALTER TABLE medication ALTER COLUMN units SET NOT NULL;
ALTER TABLE medication ALTER COLUMN dose_cost SET NOT NULL;
--============================================
create table pet_has_owner as

select tmp.* from (

with pho_scrambler as
(select round(random()*224+.5) as owner,
	generate_series(1,65) as pet
)

select p.pet_id, o.owner_id
from pet p
join pho_scrambler pho
on pho.pet = p.pet_id
join owner o
on pho.owner = o.owner_id) tmp;

ALTER TABLE pet_has_owner ADD PRIMARY KEY (pet_id, owner_id);
--============================================
CREATE TABLE procedurelookup
(
  proceduretype_id serial NOT NULL,
  procedurename character varying(45) NOT NULL,
  proccost decimal(8,2) NOT NULL,
  coveredby character varying(10) NOT NULL,
  primary key (proceduretype_id)
);

copy procedurelookup (proceduretype_id, procedurename, proccost, coveredby)
from '/Users/Shared/Data_ProcedureLookup.csv'
with CSV Header;
--============================================
create table appttype
(appttype_id serial NOT NULL,
 appttypename character varying(20) NOT NULL,
 primary key (appttype_id)
);

Insert into appttype
	(appttype_id,appttypename)
Values
(1,'well-visit'),
(2,'vaccination'),
(3,'procedure'),
(4,'follow-up'),
(5,'symptoms');
--============================================
create table appointment as

select tmp.* from (

with
appt_date_range as
(select date('2015-03-07')::date - generate_series(0,3651) as appt_date),

daily_appointments as
(select generate_series(1, 4) as daily_appt_no),

dates_with_daily_appt_nos as
(select daily_appt_no, adr.appt_date
from daily_appointments
join appt_date_range adr on 1=1
order by appt_date, daily_appt_no),

appointment_ids_with_dates as
(select row_number() over (partition by 'x') as appointment_id, daily_appt_no, appt_date
from dates_with_daily_appt_nos),

pet_id_nums as
(select generate_series(1, 65) as pet_id_num),

appt_type_nums as
(select generate_series(1, 5) as appt_type_num),

appointments_with_random_pets_and_appt_types as
(select aidd.appointment_id, aidd.appt_date,
round(random()*65+.5) as pet_random_num,
round(random()*5+.5) as appt_type_random_number
from appointment_ids_with_dates aidd
)

select appointment_id, appt_date, p.pet_id, at.appttype_id
from appointments_with_random_pets_and_appt_types
join pet p
on pet_random_num = p.pet_id
join appttype at
on appt_type_random_number = at.appttype_id) tmp;

ALTER TABLE appointment ALTER COLUMN appointment_id TYPE integer;
ALTER TABLE appointment ADD PRIMARY KEY (appointment_id);
ALTER TABLE appointment ADD FOREIGN KEY (pet_id) references pet;
ALTER TABLE appointment ADD FOREIGN KEY (appttype_id) references appttype;
--============================================
CREATE TABLE visit
(
  visit_id serial NOT NULL,
  appointment_id integer NOT NULL,
  followup_req character varying(1),
  followupdate date,
  CONSTRAINT "Visit_pkey" PRIMARY KEY (visit_id),
  CONSTRAINT "Appointment_id_fkey" FOREIGN KEY (appointment_id)
  REFERENCES appointment (appointment_id) MATCH SIMPLE
  ON UPDATE NO ACTION ON DELETE NO ACTION
);

copy visit (visit_id, appointment_id, followup_req, followupdate)
from '/Users/Shared/visit.csv'
with CSV Header;
--============================================
create table diagnosis as

select tmp.* from (
select generate_series(1,200) as diagnosis_id,
	round(random()*13156+.5)::int as visit_id, 
	round(random()*21+.5)::int as diagnosticlookup_id
) tmp;

ALTER TABLE diagnosis ADD PRIMARY KEY (diagnosis_id);
ALTER TABLE diagnosis ADD FOREIGN KEY (visit_id) references visit;
ALTER TABLE diagnosis ADD FOREIGN KEY (diagnosticlookup_id) references diagnosticlookup;
--============================================
create table prescription as

select tmp.* from (

with diag_temp as (
	select generate_series(1,200) as diagnosis_id,
	round(random()*72+.5)::int as med_id
),

diagnosis_to_med as (
select generate_series(1,200)::int as prescription_id,
	round(random()*200+.5)::int as diagnosis_id
)

select dtm.prescription_id,
	dt.diagnosis_id,
	dt.med_id
from diag_temp dt
join diagnosis_to_med dtm
on dt.diagnosis_id = dtm.diagnosis_id
	
) tmp;

ALTER TABLE prescription ADD PRIMARY KEY (prescription_id);
ALTER TABLE prescription ADD FOREIGN KEY (diagnosis_id) references diagnosis;
ALTER TABLE prescription ADD FOREIGN KEY (med_id) references medication;
--============================================
create table procedure as

select tmp.* from (

with
procedure_range as
(select generate_series(1, 10000) as procedure_id),

visit_id_nums as
(select generate_series(1, 13156) as visit_id_num),

procedure_type_nums as
(select generate_series(1, 84) as proceduretype_num),

procedures_with_visits_and_procedures as
(select pr.procedure_id,
round(random()*84+.5) as procedure_type_random_number,
round(random()*13156+.5) as visit_random_num
from procedure_range pr
)

select procedure_id, v.visit_id, pl.proceduretype_id
from procedures_with_visits_and_procedures
join visit v
on visit_random_num = v.visit_id
join procedurelookup pl
on procedure_type_random_number = pl.proceduretype_id
order by procedure_id) tmp;

ALTER TABLE procedure ADD PRIMARY KEY (procedure_id);
ALTER TABLE procedure ADD FOREIGN KEY (visit_id) references visit;
ALTER TABLE procedure ADD FOREIGN KEY (proceduretype_id) references procedure;
--============================================
----- query for basis of billing table ------ exported this to csv
--select v.visit_id, a.appointment_id, a.appt_date
--from visit v
--join appointment a on a.appointment_id = v.appointment_id
--order by v.visit_id

CREATE TABLE billing
(
  bill_id integer NOT NULL,
  visit_id integer NOT NULL,
  insureprov_id integer,
  owner_id integer,
  duedate date NOT NULL,
  billamount money NOT NULL,
  remainderdue money NOT NULL,
  CONSTRAINT "billing_pkey" PRIMARY KEY (bill_id),
  CONSTRAINT "visit_id_fkey" FOREIGN KEY (visit_id)
      REFERENCES visit (visit_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

-- added all but insureprov_id and owner_id from csv file
copy billing (bill_id, visit_id, insureprov_id, owner_id, duedate, billamount, remainderdue)
from '/Users/Shared/billing.csv'
with CSV Header;

update billing 
set insureprov_id = round(random()*10+.5);

update billing 
set insureprov_id = 100
where bill_id % 5 = 1;

update billing 
set owner_id = round(random()*224+.5)
where insureprov_id = 100;

update billing 
set insureprov_id = null
where insureprov_id = 100;

ALTER TABLE billing ADD FOREIGN KEY (visit_id) references visit;
--============================================
----- query for basis of payment table ------ exported this to csv
--select bill_id, billamount, remainderdue
--from billing
--order by bill_id

CREATE TABLE payment
(
  payment_id integer NOT NULL,
  amount money NOT NULL,
  bill_id integer NOT NULL,
  CONSTRAINT "payment_id_pkey" PRIMARY KEY (payment_id),
  CONSTRAINT "bill_id_fkey" FOREIGN KEY (bill_id)
      REFERENCES billing (bill_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

copy payment (payment_id, amount, bill_id)
from '/Users/Shared/payment.csv'
with CSV Header;
--============================================
create table account as

select tmp.* from (

with

amounts_owed_per_entity as
(select row_number() over (partition by 'x') as acct_id, insureprov_id, owner_id, (sum(remainderdue)*-1) as acct_bal
from billing
group by owner_id, insureprov_id)

select acct_id, acct_bal, insureprov_id, owner_id
from amounts_owed_per_entity
order by owner_id, insureprov_id

) tmp;

ALTER TABLE account ALTER COLUMN acct_id TYPE integer;
ALTER TABLE account ALTER COLUMN acct_bal TYPE money;
ALTER TABLE account ADD PRIMARY KEY (acct_id);
ALTER TABLE account ADD FOREIGN KEY (insureprov_id) references insprovider;
ALTER TABLE account ADD FOREIGN KEY (owner_id) references owner;
--============================================
drop table med_driver;
drop table matowns;
drop table pet_name_vals;