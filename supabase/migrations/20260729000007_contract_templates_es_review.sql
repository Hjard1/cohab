-- Spain review fixes (es templates only):
--  * purpose v3: drop unverifiable Registro de la Propiedad claim; honest
--    inscription recommendation; updates require a new signed version.
--  * assets_intro v2: "poseen conjuntamente" is wrong for assets recorded 100/0.
--  * dissolution v3: full improved structure -- valor disponible definition,
--    sale/buyout triggers, creditor carve-out, (d) deuda residual.
--  * buyout v2: lottery -> neutral third party; interest -> interés legal
--    del dinero (a real, annually set Spanish rate).
--  * disposal_consent v2: bona fide third parties protected (art. 34 LH /
--    art. 464 CC) -- state as breach between the parties.
--  * governing_law v2: acknowledge derecho civil foral (Cataluña, Navarra,
--    País Vasco, Galicia etc. have their own civil law).

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('purpose', 'es', 'OBJETO DEL CONTRATO',
 'Este contrato confirma las cuotas de propiedad que las partes han acordado entre sí sobre los activos compartidos y documenta las aportaciones económicas de cada una.{{dissolution}} No crea ni transfiere por sí mismo ningún derecho de propiedad; en el caso de los inmuebles, las cuotas deberían inscribirse también en el Registro de la Propiedad para su protección frente a terceros. Las partes se comprometen a actualizar el contrato firmando una nueva versión cuando cambien las circunstancias.',
 3, 'published'),
('assets_intro', 'es', 'ACTIVOS REGISTRADOS Y CUOTAS DE PROPIEDAD',
 'Las partes han registrado los siguientes activos en cohab en la fecha de firma y confirman las cuotas de propiedad indicadas:',
 2, 'published'),
('dissolution', 'es', 'LIQUIDACIÓN ECONÓMICA EN CASO DE VENTA, ADQUISICIÓN O SEPARACIÓN',
 'Las siguientes disposiciones constituyen el acuerdo económico propio de las partes sobre los activos registrados. Se aplican cuando la convivencia termina, cuando se vende un activo compartido y en caso de adquisición de la cuota de la otra parte. En la adquisición, el valor de mercado del activo — determinado según las reglas de valoración de este acuerdo — sustituye al precio de venta.

Por valor disponible se entiende el valor de venta o adquisición del activo menos los préstamos que lo gravan y los costes razonables de la venta. Este acuerdo no afecta a los derechos de bancos ni de otros acreedores.

(a) Las aportaciones se devuelven primero. Lo que cada parte ha aportado — con los intereses acumulados ({{rate}} anual hasta la fecha de pago) — se devuelve a esa parte antes de distribuir el valor restante.

(b) Déficit. Si el valor disponible es inferior al total de las aportaciones, se distribuye proporcionalmente a lo aportado por cada parte.

(c) Excedente. El saldo eventual tras la devolución de aportaciones se distribuye conforme a las cuotas de propiedad acordadas.

(d) Deuda residual. Si el valor no cubre siquiera los préstamos y los costes de venta, las partes asumen la deuda restante entre sí en proporción a sus cuotas de propiedad.

Este acuerdo no es un testamento y no regula la herencia. Si la convivencia termina por el fallecimiento de una parte, se aplica la legislación sucesoria — se recomienda a las partes otorgar testamento.',
 3, 'published'),
('buyout', 'es', 'DERECHO DE ADQUISICIÓN PREFERENTE',
 'Si la convivencia termina y las partes son copropietarias de un inmueble:

(a) Derecho preferente. La parte con mayor cuota registrada tiene derecho a adquirir la parte de la otra. En caso de igualdad (50/50), se intentará primero un acuerdo escrito; si no se alcanza en 30 días, el derecho se determina por mediación o, si fracasa, por un tercero neutral designado de común acuerdo por las partes.

(b) Valoración. El precio de adquisición es la media de dos tasaciones independientes, una por parte.

(c) Plazo. La adquisición o venta en mercado abierto debe completarse en 6 meses desde la notificación escrita.

(d) Intereses de demora. Si se supera el plazo, la parte incumplidora pagará intereses al tipo de interés legal del dinero vigente.',
 2, 'published'),
('disposal_consent', 'es', 'CONSENTIMIENTO PARA DISPOSICIÓN',
 'Ninguna parte podrá vender, arrendar, hipotecar o disponer de los activos compartidos sin el consentimiento escrito previo de la otra. La disposición sin dicho consentimiento constituye un incumplimiento contractual entre las partes; los derechos de los terceros de buena fe no se ven afectados.',
 2, 'published'),
('governing_law', 'es', 'LEY APLICABLE',
 'Este contrato se rige por la legislación española y, en los territorios con derecho civil propio, por la normativa civil foral aplicable. Las disputas que no puedan resolverse amistosamente se someterán a los tribunales competentes de la jurisdicción donde se encuentre el activo principal compartido.',
 2, 'published')
on conflict (clause_key, language, version) do nothing;
