﻿﻿--1
CREATE DATABASE Ispit4
GO

USE Ispit4
GO

/*
a) 
Kreirati tabelu dobavljac sljedeće strukture:
	- dobavljac_id - cjelobrojna vrijednost, primarni ključ
	- dobavljac_br_rac - 50 unicode karaktera
	- naziv_dobavljaca - 50 unicode karaktera
	- kred_rejting - cjelobrojna vrijednost
*/
create table dobavljac(
	dobavljac_id int primary key,
	dobavljac_br_rac nvarchar(50),
	naziv_dobavljaca nvarchar(50),
	kred_rejting int
)
go


/*
b)
Kreirati tabelu narudzba sljedeće strukture:
	- narudzba_detalj_id - cjelobrojna vrijednost, primarni ključ
	- narudzba_id - cjelobrojna vrijednost
	- dobavljac_id - cjelobrojna vrijednost
	- dtm_narudzbe - datumska vrijednost
	- naruc_kolicina - cjelobrojna vrijednost
	- cijena_proizvoda - novčana vrijednost
*/
create table narudzba(
	narudzba_detalj_id int primary key,
	narudzba_id int,
	dobavljac_id int foreign key references dobavljac(dobavljac_id),
	dtm_narudzbe datetime,
	naruc_kolicina int,
	cijena_proizvoda money
)
go


/*
c)
Kreirati tabelu dobavljac_proizvod sljedeće strukture:
	- proizvod_id cjelobrojna vrijednost, primarni ključ
	- dobavljac_id cjelobrojna vrijednost, primarni ključ
	- proiz_naziv 50 unicode karaktera
	- serij_oznaka_proiz 50 unicode karaktera
	- razlika_min_max cjelobrojna vrijednost
	- razlika_max_narudzba cjelobrojna vrijednost
*/
create table dobavljac_proizvod(
	proizvod_id int,
	dobavljac_id int,
	proiz_naziv nvarchar(50),
	serij_oznaka_proiz nvarchar(50),
	razlika_min_max int,
	razlika_max_narudzba int,
	constraint PK_DP primary key (proizvod_id, dobavljac_id),
	constraint FK_DP_Dobavljac foreign key(dobavljac_id) references dobavljac(dobavljac_id) 
)


----------------------------
--2. Insert podataka
----------------------------
/*
a) 
U tabelu dobavljac izvršiti insert podataka iz tabele Purchasing.Vendor prema sljedećoj strukturi:
	BusinessEntityID -> dobavljac_id 
	AccountNumber -> dobavljac_br_rac 
	Name -> naziv_dobavljaca
	CreditRating -> kred_rejting
*/
insert into dobavljac(dobavljac_id, dobavljac_br_rac, naziv_dobavljaca, kred_rejting)
select  BusinessEntityID, AccountNumber, [Name], CreditRating
from AdventureWorks2017.Purchasing.Vendor
go

/*
	U tabelu narudzba izvršiti insert podataka iz tabela Purchasing.PurchaseOrderHeader i Purchasing.PurchaseOrderDetail prema sljedećoj strukturi:
	PurchaseOrderID -> narudzba_id
	PurchaseOrderDetailID -> narudzba_detalj_id
	VendorID -> dobavljac_id 
	OrderDate -> dtm_narudzbe 
	OrderQty -> naruc_kolicina 
	UnitPrice -> cijena_proizvoda
*/
select top 3 * from AdventureWorks2017.Purchasing.PurchaseOrderHeader
select top 3 * from AdventureWorks2017.Purchasing.PurchaseOrderDetail

insert into narudzba(narudzba_id, narudzba_detalj_id, dobavljac_id, dtm_narudzbe, naruc_kolicina, cijena_proizvoda)
select poh.PurchaseOrderID, pod.PurchaseOrderDetailID, poh.VendorID, poh.OrderDate, pod.OrderQty, pod.UnitPrice
from AdventureWorks2017.Purchasing.PurchaseOrderHeader poh join AdventureWorks2017.Purchasing.PurchaseOrderDetail pod
on poh.PurchaseOrderID=pod.PurchaseOrderID


/*
c) 
U tabelu dobavljac_proizvod izvršiti insert podataka iz tabela Purchasing.ProductVendor i Production.Product prema sljedećoj strukturi:
	ProductID -> proizvod_id 
	BusinessEntityID -> dobavljac_id 
	Name -> proiz_naziv 
	ProductNumber -> serij_oznaka_proiz
	MaxOrderQty - MinOrderQty -> razlika_min_max 
	MaxOrderQty - OnOrderQty -> razlika_max_narudzba
uz uslov da se dohvate samo oni zapisi u kojima se podatak u koloni rowguid tabele Production.Product završava cifrom.
*/
select top 3 * from AdventureWorks2017.Purchasing.ProductVendor
select top 3 * from AdventureWorks2017.Production.Product
go
insert into dobavljac_proizvod(proizvod_id, dobavljac_id, proiz_naziv, serij_oznaka_proiz, razlika_min_max, razlika_max_narudzba)
select p.ProductID,  pv.BusinessEntityID, p.Name, p.ProductNumber, pv.MaxOrderQty-pv.MinOrderQty, pv.MaxOrderQty-pv.OnOrderQty
from AdventureWorks2017.Purchasing.ProductVendor pv join AdventureWorks2017.Production.Product p
on pv.ProductID = p.ProductID
go
---------------------
--3.
----------------------------
/*
Koristeći sve tri tabele iz vlastite baze kreirati pogled view_dob_proiz sljedeće strukture:
	- dobavljac_id
	- proizvod_id
	- naruc_kolicina
	- cijena_proizvoda
	- razlika, kao razlika kolona razlika_min_max i razlika_max_narudzba 
Uslov je da se dohvate samo oni zapisi u kojima je razlika pozitivan broj ili da je kreditni rejting 1.
*/
create or alter view view_dob_proiz as
select d.dobavljac_id, dp.proizvod_id, n.naruc_kolicina, n.cijena_proizvoda, dp.razlika_min_max-dp.razlika_max_narudzba as razlika
from dobavljac d join dobavljac_proizvod dp on d.dobavljac_id=dp.dobavljac_id
join narudzba n on n.dobavljac_id=d.dobavljac_id
where dp.razlika_min_max-dp.razlika_max_narudzba>0 or d.kred_rejting=1
go
select * from view_dob_proiz
go

----------------------------
--4.
----------------------------
/*
Koristeći pogled view_dob_proiz kreirati proceduru proc_dob_proiz koja će sadržavati parametar razlika i imati sljedeću strukturu:
	- dobavljac_id
	- suma_razlika, sumirana vrijednost kolone razlika po dobavljac_id i proizvod_id
Uslov je da se dohvataju samo oni zapisi u kojima je razlika jednocifren ili dvocifren broj.
Nakon kreiranja pokrenuti proceduru za vrijednost razlike 2.
*/

create or alter proc proc_dob_proiz @razlika int as
begin
	select dobavljac_id, SUM(razlika) as sumaRazlika
	from view_dob_proiz
	where razlika between 0 and 99
	group by dobavljac_id, proizvod_id
end
go
exec proc_dob_proiz 2
go
----------------------------
--5.
----------------------------
/*
a)
Pogled view_dob_proiz kopirati u tabelu tabela_dob_proiz uz uslov da se ne dohvataju zapisi u kojima je razlika NULL vrijednost
--11051
*/

select *  
into tabela_dob_proiz 
from view_dob_proiz  
where razlika is not null 
go
select * from tabela_dob_proiz
go
/*
b) 
U tabeli tabela_dob_proiz kreirati izračunatu kolonu ukupno kao proizvod naručene količine i cijene proizvoda.
*/
alter table tabela_dob_proiz
add ukupno as (naruc_kolicina*cijena_proizvoda)
go
select * from tabela_dob_proiz
go
/*
c)
U tabeli tabela_dob_god kreirati novu kolonu razlika_ukupno. Kolonu popuniti razlikom vrijednosti kolone ukupno i srednje vrijednosti ove kolone. Negativne vrijednosti u koloni razlika_ukupno zamijeniti 0.
*/
alter table tabela_dob_proiz 
add razlika_ukupno  money 

update tabela_dob_proiz
set razlika_ukupno =
	case 
		when ukupno-(select AVG(ukupno) from tabela_dob_proiz)<0 then 0
		else ukupno-(select AVG(ukupno) from tabela_dob_proiz)
	end
select * from tabela_dob_proiz
----------------------------
--6.
----------------------------
/*
Prebrojati koliko u tabeli dobavljac_proizvod ima različitih serijskih oznaka proizvoda kojima se poslije 
prve srednje crte nalazi bilo koje slovo engleskog alfabeta, a koliko ima onih kojima se poslije prve 
srednje crte nalazi cifra. Upit treba da vrati dvije poruke (tekst i podaci se ne prikazuju u zasebnim kolonama):
'Različitih serijskih oznaka proizvoda koje završavaju slovom engleskog alfabeta ima: ' iza čega slijedi 
podatak o ukupno prebrojanom  broju zapisa i 'Različitih serijskih oznaka proizvoda kojima se 
poslije prve srednje crte nalazi cifra ima:' iza čega slijedi podatak o ukupno prebrojanom  broju zapisa 
*/
select serij_oznaka_proiz from dobavljac_proizvod

select 'Različitih serijskih oznaka proizvoda koje završavaju slovom engleskog alfabeta ima: ' + cast(count(serij_oznaka_proiz) as nvarchar) as Broj
from dobavljac_proizvod
--where ISNUMERIC(right(LEFT(serij_oznaka_proiz,4),1))=0
where right(LEFT(serij_oznaka_proiz,4),1) not like '[0-9]' --drugi nacin
union 
select 'Različitih serijskih oznaka proizvoda kojima se 
poslije prve srednje crte nalazi cifra ima:' + cast(count(serij_oznaka_proiz) as nvarchar) as Broj
from dobavljac_proizvod
where ISNUMERIC(right(LEFT(serij_oznaka_proiz,4),1))=1
----------------------------
--7.
----------------------------
/*
a)
Koristeći tabelu dobavljac kreirati pogled view_duzina koji će sadržavati slovni dio podataka u koloni dobavljac_br_rac, te broj znakova slovnog dijela podatka.
*/
select dobavljac_br_rac from dobavljac
go
create or alter view view_duzina as
select left(dobavljac_br_rac, PATINDEX('%[0-9]%', dobavljac_br_rac + '0') - 1) as slova,
LEN(left(dobavljac_br_rac, PATINDEX('%[0-9]%', dobavljac_br_rac + '0') - 1)) as brojZnakova
from dobavljac
go
select CONVERT(nvarchar(8), dobavljac_br_rac)  from dobavljac
select COUNT(*) from view_duzina
/*
b)
Koristeći pogled view_duzina odrediti u koliko zapisa broj prebrojanih znakova je veći ili jednak, a koliko manji od srednje vrijednosti prebrojanih brojeva znakova. Rezultat upita trebaju biti dva reda sa odgovarajućim porukama.
*/


select 'Veci od srednje vrijednosti:' + CAST(count(brojZnakova) as nvarchar)
from view_duzina
where brojZnakova>=(select AVG(brojZnakova) from view_duzina)
union 
select 'Manji od srednje vrijednosti:' + CAST(count(brojZnakova) as nvarchar)
from view_duzina
where brojZnakova < (select AVG(brojZnakova) from view_duzina)

----------------------------
--8.
----------------------------
/*
Prebrojati kod kolikog broja dobavljača je broj računa kreiran korištenjem više od jedne riječi iz naziva dobavljača. Jednom riječi se podrazumijeva skup slova koji nije prekinut blank (space) znakom. 
*/
select COUNT(*) from dobavljac
where naziv_dobavljaca like '% %' and
	dobavljac_br_rac like '%' + LEFT(naziv_dobavljaca, CHARINDEX(' ', naziv_dobavljaca)-1)+'%' -- prva rijec imena do ' '
	and
	dobavljac_br_rac like '%' + SUBSTRING(naziv_dobavljaca, CHARINDEX(' ', naziv_dobavljaca)+1, 50)+'%'


----------------------------
--9.
----------------------------
/*
a) U tabeli dobavljac_proizvod id proizvoda promijeniti tako što će se sve trocifrene vrijednosti svesti na vrijednost stotina (npr. 524 => 500). Nakon toga izvršiti izmjenu vrijednosti u koloni proizvod_id po sljedećem pravilu:
- Prije postojeće vrijednosti dodati "pr-", 
- Nakon postojeće vrijednosti dodati srednju crtu i četverocifreni brojčani dio iz kolone serij_oznaka_proiz koji slijedi nakon prve srednje crte, pri čemu se u slučaju da četverocifreni dio počinje 0 ta 0 odbacuje. 
U slučaju da nakon prve srednje crte ne slijedi četverocifreni broj ne vrši se nikakvo dodavanje (ni prije, ni poslije postojeće vrijednosti)
*/
/*
Primjer nekoliko konačnih podatka:

proizvod_id		serij_oznaka_proit

pr-300-1200		FW-1200
pr-300-820 		GT-0820 (odstranjena 0)
700				HL-U509-R (nije izvršeno nikakvo dodavanje)
*/
select 
 case 
		when ISNUMERIC(right(LEFT(serij_oznaka_proiz,4),1))=1 and isnumeric(right(left(serij_oznaka_proiz,7),1))=1 --4 i 7 elem su brojevi onda je 4cifren
				then 'pr-'+cast(proizvod_id-(RIGHT(proizvod_id, 2)) as varchar) + '-'+cast(CAST(right(LEFT(serij_oznaka_proiz,7),4) as int) as varchar)  
		when ISNUMERIC(right(LEFT(serij_oznaka_proiz,4),1))=1 and isnumeric(right(left(serij_oznaka_proiz,7),1))=0  then cast(right(left(serij_oznaka_proiz,6),3) as varchar) end as proizvod_id -- jer je proizvod_id definisan kao int, a ovo ga u varchar mora pretvoriti,a da se sad ne bi patili sa alteranjem kroz tabele i ključeve ostavljamo opticku varku lol
			--4. je broj ali 7. nije znac da je 3cifren
from dobavljac_proizvod
where  proizvod_id between 100 and 999 
				
----------------------------
--10.
----------------------------
/*
a) Kreirati backup baze na default lokaciju.
b) Napisati kod kojim će biti moguće obrisati bazu.
c) Izvršiti restore baze.
Uslov prihvatanja kodova je da se mogu pokrenuti.
*/
backup database Ispit4
to disk = 'C:\BackupSQL\Ispit4.bak'
go
drop database Ispit4
go