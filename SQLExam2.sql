﻿﻿/*
1.a) Kreirati bazu pod vlastitim brojem indeksa.
*/
create database Ispit22
go
use Ispit22
go
/*
1.b) Kreiranje tabela.

Prilikom kreiranja tabela voditi računa o odnosima između tabela.
I. Kreirati tabelu produkt sljedeće strukture:
	- produktID, cjelobrojna varijabla, primarni ključ
	- jed_cijena, novčana varijabla
	- kateg_naziv, 15 unicode karaktera
	- mj_jedinica, 20 unicode karaktera
	- dobavljac_naziv, 40 unicode karaktera
	- dobavljac_post_br, 10 unicode karaktera
*/

create table Produkt(
	produktID int constraint PK_Produkt primary key,
	jed_cijena money,
	kateg_naziv nvarchar(15),
	mj_jedinica nvarchar(20),
	dobavljac_naziv nvarchar(40),
	dobavljac_post_br nvarchar(10)
)
go

/*
II. Kreirati tabelu narudzba sljedeće strukture:
	- narudzbaID, cjelobrojna varijabla, primarni ključ
	- dtm_narudzbe, datumska varijabla za unos samo datuma
	- dtm_isporuke, datumska varijabla za unos samo datuma
	- grad_isporuke, 15 unicode karaktera
	- klijentID, 5 unicode karaktera
	- klijent_naziv, 40 unicode karaktera
	- prevoznik_naziv, 40 unicode karaktera
*/

create table Narudzba(
	narudzbaID int constraint PK_Narudzba primary key,
	dtm_narudzbe date,
	dtm_isporuke date,
	grad_isporuke nvarchar(15),
	klijentID nvarchar(5),
	klijent_naziv nvarchar(40),
	prevoznik_naziv nvarchar(40)
)
go

/*

III. Kreirati tabelu narudzba_produkt sljedeće strukture:
	- narudzbaID, cjelobrojna varijabla, obavezan unos
	- produktID, cjelobrojna varijabla, obavezan unos
	- uk_cijena, novčana varijabla

----------------------------------------------------------------------------------------------------------------------------
*/
create table narudzba_produkt(
	narudzbaID int not null,
	produktID int not null,
	uk_cijena money
	constraint PK_NarudzbaProdukt primary key(narudzbaID, produktID),
	constraint FK_NP_Narudzba foreign key(narudzbaID) references Narudzba(narudzbaID),
	constraint FK_NP_Produkt foreign key(produktID) references Produkt(produktID)
)go

/*2. Import podataka

a) Iz tabela Categories, Product i Suppliers baze Northwind u tabelu produkt importovati podatke prema pravilu:
	- ProductID -> produktID
	- QuantityPerUnit -> mj_jedinica
	- UnitPrice -> jed_cijena
	- CategoryName -> kateg_naziv
	- CompanyName -> dobavljac_naziv
	- PostalCode -> dobavljac_post_br
*/
insert into Produkt(produktID, mj_jedinica, jed_cijena, kateg_naziv, dobavljac_naziv, dobavljac_post_br)
select  p.ProductID, p.QuantityPerUnit, p.UnitPrice, c.CategoryName, s.CompanyName, s.PostalCode
from NORTHWND.dbo.Categories c join NORTHWND.dbo.Products p on c.CategoryID=p.CategoryID
join NORTHWND.dbo.Suppliers s on s.SupplierID=p.SupplierID
go
/*
b) Iz tabela Customers, Orders i Shipers baze Northwind u tabelu narudzba importovati podatke prema pravilu:
	- OrderID -> narudzbaID
	- OrderDate -> dtm_narudzbe
	- ShippedDate -> dtm_isporuke
	- ShipCity -> grad_isporuke
	- CustomerID -> klijentID
	- CompanyName -> klijent_naziv
	- CompanyName -> prevoznik_naziv
*/
select top 3 * from NORTHWND.dbo.Customers
select top 3 * from NORTHWND.dbo.Orders
select top 3 * from NORTHWND.dbo.Shippers
go
insert into Narudzba(narudzbaID, dtm_narudzbe, dtm_isporuke, grad_isporuke, klijentID, klijent_naziv, prevoznik_naziv)
select o.OrderID, o.OrderDate, o.ShippedDate, o.ShipCity, c.CustomerID, c.CompanyName, s.CompanyName
from NORTHWND.dbo.Customers c join NORTHWND.dbo.Orders o on c.CustomerID =o.CustomerID
join NORTHWND.dbo.Shippers s on s.ShipperID = o.ShipVia
go

/*

c) Iz tabele Order Details baze Northwind u tabelu narudzba_produkt importovati podatke prema pravilu:
	- OrderID -> narudzbaID
	- ProductID -> produktID
	- uk_cijena <- produkt jedinične cijene i količine
   uz uslov da je odobren popust 5% na produkt.
   */
   insert into narudzba_produkt(narudzbaID, produktID,uk_cijena)
   select OrderID, ProductID, UnitPrice*Quantity
   from NORTHWND.dbo.[Order Details]
   where Discount = 0.05
go

/*
3. a) Koristeći tabele narudzba i narudzba_produkt kreirati pogled view_uk_cijena koji će imati strukturu:
	- narudzbaID
	- klijentID
	- uk_cijena_cijeli_dio
	- uk_cijena_feninzi - prikazati kao cijeli broj  
      Obavezno pregledati sadržaj pogleda.
*/
create or alter view view_uk_cijena as
select n.narudzbaID, n.klijentID,
	(case when RIGHT(np.uk_cijena, 2)>=50 then CAST(np.uk_cijena AS int)-1 else CAST(np.uk_cijena AS int) end) as uk_cijena_cijeli_dio, 
	CAST(RIGHT(np.uk_cijena, 2) as int) as  uk_cijena_feninzi
from Narudzba n join narudzba_produkt np on n.narudzbaID=np.narudzbaID
go

select * from view_uk_cijena 
go
select * from narudzba_produkt 
/*

b) Koristeći pogled view_uk_cijena kreirati tabelu nova_uk_cijena uz uslov da se preuzmu samo oni zapisi u kojima su feninzi veći od 49. 
   U tabeli trebaju biti sve kolone iz pogleda, te nakon njih kolona uk_cijena_nova u kojoj će ukupna cijena biti zaokružena na veću vrijednost. 
   Npr. uk_cijena = 10, feninzi = 90 -> uk_cijena_nova = 11

----------------------------------------------------------------------------------------------------------------------------
*/
create table nova_uk_cijena(
	narudzbaID int ,
	klijentID nvarchar(5),
	uk_cijena_cijeli_dio int,
	uk_cijena_feninzi int,
	uk_cijena_nova int
)
go

insert into nova_uk_cijena(narudzbaID, klijentID,uk_cijena_cijeli_dio, uk_cijena_feninzi, uk_cijena_nova)
select narudzbaID, klijentID, uk_cijena_cijeli_dio, uk_cijena_feninzi, uk_cijena_cijeli_dio+1
from view_uk_cijena
where uk_cijena_feninzi>49
go

select * from nova_uk_cijena
go
/*
4. Koristeći tabelu uk_cijena_nova kreiranu u 3. zadatku kreirati proceduru tako da je prilikom izvršavanja moguće unijeti bilo koji broj parametara 
   (možemo ostaviti bilo koji parametar bez unijete vrijednosti). Proceduru pokrenuti za sljedeće vrijednosti varijabli:
	narudzbaID - 10730
	klijentID  - ERNSH
----------------------------------------------------------------------------------------------------------------------------
*/
create or alter proc unosUCN
	@narudzbaID int = null,
	@klijentID nvarchar(5)=null,
	@uk_cijena_cijeli_dio int = null,
	@uk_cijena_feninzi int = null,
	@uk_cijena_nova int = null
as
begin
	insert into nova_uk_cijena(narudzbaID, klijentID, uk_cijena_cijeli_dio, uk_cijena_feninzi, uk_cijena_nova)
	values (@narudzbaID, @klijentID, @uk_cijena_cijeli_dio, @uk_cijena_feninzi, @uk_cijena_nova)
end
go
exec unosUCN
select * from nova_uk_cijena where narudzbaID is null

/*
5. Koristeći tabelu produkt kreirati proceduru proc_post_br koja će prebrojati zapise u kojima poštanski broj dobavljača počinje cifrom. 
   Potrebno je dati prikaz poštanskog broja i ukupnog broja zapisa po poštanskom broju. Nakon kreiranja pokrenuti proceduru.
----------------------------------------------------------------------------------------------------------------------------
*/select count(dobavljac_post_br) from Produkt where ISNUMERIC(LEFT(dobavljac_post_br,1))=1
go
create or alter proc proc_post_br as
begin
	select dobavljac_post_br as [Postanski Broj],count(dobavljac_post_br) as [Ukupni broj zapisa po poštanskom broju]
	from Produkt where ISNUMERIC(LEFT(dobavljac_post_br,1))=1
	group by dobavljac_post_br
end
go

exec proc_post_br

select dobavljac_post_br from Produkt where dobavljac_post_br like '100%'
/*
6. a) Iz tabele narudzba kreirati pogled view_prebrojano sljedeće strukture:
	- klijent_naziv
	- prebrojano - ukupan broj narudžbi po nazivu klijent
      Obavezno napisati naredbu za pregled sadržaja pogleda.
   b) Napisati naredbu kojom će se prikazati maksimalna vrijednost kolone prebrojano.
   c) Iz pogleda kreiranog pod a) dati pregled zapisa u kojem će osim kolona iz pogleda prikazati razlika maksimalne vrijednosti i kolone prebrojano 
      uz uslov da se ne prikazuje zapis u kojem se nalazi maksimlana vrijednost.
*/go
create or alter view view_prebrojano as
select klijent_naziv, COUNT(narudzbaID) as prebrojano
from Narudzba
group by klijent_naziv
go
select * from view_prebrojano
go
--b)
select MAX(prebrojano) as NajveciBrojNarudzbi from view_prebrojano
--c
select klijent_naziv, prebrojano, (select MAX(prebrojano) from view_prebrojano)-prebrojano
from view_prebrojano
where prebrojano != (select MAX(prebrojano) from view_prebrojano)
group by klijent_naziv,prebrojano
order by 3
go
/*
7. a) U tabeli produkt dodati kolonu lozinka, 20 unicode karaktera 
   b) Kreirati proceduru kojom će se izvršiti punjenje kolone lozinka na sljedeći način:
	- ako je u dobavljac_post_br podatak sačinjen samo od cifara, lozinka se kreira obrtanjem niza znakova koji se dobiju spajanjem zadnja četiri znaka kolone mj_jedinica i kolone dobavljac_post_br
	- ako podatak u dobavljac_post_br podatak sadrži jedno ili više slova na bilo kojem mjestu, lozinka se kreira obrtanjem slučajno generisanog niza znakova
      Nakon kreiranja pokrenuti proceduru.
      Obavezno provjeriti sadržaj tabele narudžba.
	*/

alter table Produkt
add lozinka nvarchar(20)
go
create or alter proc popuniLozinka as
begin
	update Produkt
	set lozinka = (case when ISNUMERIC(dobavljac_post_br)=1 then reverse(RIGHT(mj_jedinica,4)+dobavljac_post_br)
	else reverse(left(NEWID(),20))end)
	from Produkt
end
go

exec popuniLozinka
select * from Produkt
go

		/*8. a) Kreirati pogled kojim sljedeće strukture:
	- produktID,
	- dobavljac_naziv,
	- grad_isporuke
	- period_do_isporuke koji predstavlja vremenski period od datuma narudžbe do datuma isporuke
      Uslov je da se dohvate samo oni zapisi u kojima je narudzba realizirana u okviru 4 sedmice .
      Obavezno pregledati sadržaj pogleda.

   b) Koristeći pogled view_isporuka kreirati tabelu isporuka u koju će biti smještene sve kolone iz pogleda. 
----------------------------------------------------------------------------------------------------------------------------*/
go
create or alter view view_isporuka as
select p.produktID, p.dobavljac_naziv, n.grad_isporuke, DATEDIFF(DAY, n.dtm_narudzbe, n.dtm_isporuke) as period_do_isporuke
from Narudzba n join narudzba_produkt np on n.narudzbaID = np.narudzbaID
join Produkt p on np.produktID=p.produktID
where DATEDIFF(DAY, n.dtm_narudzbe, n.dtm_isporuke)<=28
go
select * from view_isporuka order by 4
go

select * into isporuka from view_isporuka
go
select * from isporuka order by 4
/*9.  a) U tabeli isporuka dodati kolonu red_br_sedmice, 10 unicode karaktera.
    b) U tabeli isporuka izvršiti update kolone red_br_sedmice ( prva, druga, treca, cetvrta) u zavisnosti od vrijednosti u koloni period_do_isporuke. Pokrenuti proceduru
    c) Kreirati pregled kojim će se prebrojati broj zapisa po rednom broju sedmice. Pregled treba da sadrži redni broj sedmice i ukupan broj zapisa po rednom broju.
----------------------------------------------------------------------------------------------------------------------------*/
go
alter table isporuka
add red_br_sedmice nvarchar(10)
go
select * from isporuka
go
create or alter proc updateRedBrSedmice as
begin
	update isporuka
	set red_br_sedmice = case
	when period_do_isporuke between 1 and 7 then 'prva'
	when period_do_isporuke between 8 and 14 then 'druga'
	when period_do_isporuke between 15 and 21 then 'treća'
	when period_do_isporuke between 22 and 28 then 'četvrta'
	end
end
go
exec updateRedBrSedmice
go
select * from isporuka order by period_do_isporuke
go


/*10. a) Kreirati backup baze na default lokaciju.
    b) Kreirati proceduru kojom će se u jednom izvršavanju obrisati svi pogledi i procedure u bazi. Pokrenuti proceduru.
	*/
	--a
	backup database Ispit22
	to disk='C:\BackupSQL\Ispit22.bak'
	go
	--b
	create or alter proc brisanje as
	begin
	drop view view_isporuka,view_prebrojano, view_uk_cijena
	drop procedure popuniLozinka, proc_post_br, unosUCN, updateRedBrSedmice
	end
	go

	exec brisanje

