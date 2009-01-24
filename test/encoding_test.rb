#!/usr/bin/env ruby
#
#  Created by Brent Rowland on 2009-01-24.
#  Copyright (c) 2009, Eidetic Software. All rights reserved.

$: << File.dirname(__FILE__) + '/../'
require 'epdfdw'

start = Time.now
docw = EideticPDF::DocumentWriter.new

docw.doc(:font => { :name => 'Times-Roman', :size => 12 }, :units => :in, :margins => 0.5, :text_encoding => 'UTF8') do |w|
  lines = DATA.readlines.map { |line| line.split(' ', 2) }
  lines.each do |line|
    w.font_encoding line[0]
    w.paragraph line[1]
  end
end

File.open("encoding_test.pdf","w") { |f| f.write(docw) }

elapsed = Time.now - start
puts "Elapsed: #{(elapsed * 1000).round} ms"
`open encoding_test.pdf`

__END__
CP1252 Danish: Oplysningerne på denne side afspejler de vurderinger, der er blevet tildelt, og hvad der er blevet gennemført.
CP1252 Spanish: La información mencionada en esta página refleja las evaluaciones que le han sido asignadas y las que usted ya ha terminado.
CP1252 French: Les informations listées sur cette page sont le reflet des évaluations qui ont été affectées et réalisées.
CP1250 Croatian: Informacija na ovoj stranici Vam pokazuje status vaše analize.
CP1250 Hungarian: Ezen az oldalon azokat a kérdőíveket találja, melynek kitöltésével már elkészült.
CP1252 Norwegian: Informasjonen på denne siden viser analysene som du skal gjennomføre og hva som er gjennomført.
CP1250 Polish: Informacja znajdująca się na tej stronie przedstawia ocenę postępów, oszacowania, które zostały oznaczone i co zostało uzupełnione.
CP1252 Portuguese: As informações apresentadas nesta página refletem as avaliações disponibilizadas e o que já foi concluído.
CP1250 Romanian: Informaţiile afişate pe pagina asta reflectă evaluările alocate si cele care au fost deja completate.
CP1250 Slovene: Poročilo na tej strani odraža oceno, ki je bila dodeljena in kaj je bilo dokončano.
CP1250 Slovak: Informácie uvedené na tejto stránke popisujú hodnotiace testy, ktoré boli určené a ktoré boli ukončené.
CP1252 Finnish: Tällä sivulla oleva informaatio koskee arviointeja, jotka on annettu ja päätetty.
CP1252 Swedish: Informationen på den här sidan visar vilka moment som är aktiva och vilka som är slutförda.
CP1254 Turkish: Bu sayfada sıralanan bilgiler sizin için seçilmiş ölçme ve değerlendirme araçlarını ve bunlardan doldurup tamamladıklarınızı yansıtır.
CP1250 Czech: Informace uvedené na této stránce popisují hodnotící testy, které byly přiděleny a vyplněny.
