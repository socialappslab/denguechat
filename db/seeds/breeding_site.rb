# encoding: UTF-8

def seed_breeding_sites_and_elimination_methods
  puts "-" * 80
  puts "[!] Seeding elimination types and methods..."
  puts "\n" * 3

  types_and_methods = [
    {
      :breeding_site_in_pt => "Pratinho de planta",
      :breeding_site_in_es => "Plato pequeño de maceta",
      :elimination_methods_in_pt => [
        {:method => "Elimine fazendo furos no pratinho", :points => 200},
        {:method => "Prato removido (ou seja, não mais utilizado)", :points => 200},
        {:method => "Coloque areia", :points => 200},
        {:method => "Retire a água e esfregue para remover possíveis ovos (uma vez por semana).", :points => 50}
      ],
      :elimination_methods_in_es => [
        {:method => "Elimine haciendo agujeros en el plato", :points => 200},
        {:method => "Plato removido (es decir, no se utilizará más)", :points => 200},
        {:method => "Coloque arena", :points => 200},
        {:method => "Retire el agua y limpie para remover posibles huevos (una vez por semana).", :points => 50}
      ]
    },

    {
      :breeding_site_in_pt => "Pneu",
      :breeding_site_in_es => "Llanta",
      :elimination_methods_in_pt => [
        {:method => "Desfaça-se do pneu (entregue ao serviço de limpeza)", :points => 50},
        {:method => "Arranje um uso alternativo para o pneu: preencha com terra e faça uma horta; preencha com areia, terra e cimento e utilize como degrau.", :points => 450},
        {:method => "Transferir o pneu sem água para um local coberto e seco.", :points => 100},
        {:method => "Cubra o pneu com algo que não se transforme em um foco potencial do mosquito.", :points => 100}
      ],
      :elimination_methods_in_es => [
        {:method => "Deshágase de la llanta (entregue al servicio de limpieza)", :points => 50},
        {:method => "Organice un uso alternativo para la llanta: rellenar con tierra para hacer una jardinera; rellenar con tierra y hacer una hortaliza; rellenar con arena, tierra y cemento y utilizar como punto de paso.", :points => 450},
        {:method => "Transferir la llanta a un lugar cubierto y seco.", :points => 100},
        {:method => "Cubra la llanta con algo que no se transforme en un foco potencial de mosquitos.", :points => 100}
      ]
    },

    {
      :breeding_site_in_pt => "Lixo (recipientes inutilizados)",
      :breeding_site_in_es => "Basura (recipientes inutilizados)",
      :elimination_methods_in_pt => [
        {:method => "Jogá-los em uma lixeira bem tampada.", :points => 0},
        {:method => "Organize um mutirão de limpeza na vizinhança (coordenado pelos Agentes de Vigilância Sanitária) OBS: em locais onde não há atuação dos garis comunitários.", :points => 450},
        {:method => "Participe de um mutirão de limpeza na vizinhança (coordenado pelos Agentes de Vigilância Sanitária) OBS: em locais onde não há atuação dos garis comunitários.", :points => 350}
      ],

      :elimination_methods_in_es => [
        {:method => "Tire la basura en un basurero bien tapado.", :points => 0},
        {:method => "Organice una campaña para limpiar el barrio (coordinado por los Agentes de Vigilancia Sanitaria) Ejemplo: Busque lugares donde no tienen acceso los barrenderos de la comunidad", :points => 450},
        {:method => "Únase a una campaña para limpiar el barrio (coordinado por los Agentes de Vigilancia Sanitaria) Ejemplo: en lugares donde no tienen acceso los barrenderos de la comunidad. ", :points => 350}
      ]
    },

    {
      :breeding_site_in_pt => "Pequenos Recipientes utilizáveis Garrafas de vidro, vasos, baldes, tigela de água de cachorro",
      :breeding_site_in_es => "Botellas de pequeños contenedores de vidrio utilizable, jarrones, cubetas, tazón de agua de mascotas",
      :elimination_methods_in_pt => [
        {:method => "Remova a água e esfregue uma vez por semana; ou, no caso de bebedouros de animais e aves, trocar a água e limpar diariamente.", :points => 50},
        {:method => "Elimine fazendo furos no pratinho", :points => 200}
      ],

      :elimination_methods_in_es => [
        {:method => "Remueva el agua y talle una vez por semana; en caso de ser bebedero de animales o aves, cambiar el agua diariamente.", :points => 50},
        {:method => "Elimine fazendo furos no pratinho", :points => 200}
      ]
    },

    {
      :breeding_site_in_pt => "Grandes Recipientes Utilizáveis Tonéis, outras depósitos de água, pias, galões d’água.",
      :breeding_site_in_es => "Recipientes grandes utilizables, toneles, galones, piletas, otros depósitos de agua.",
      :elimination_methods_in_pt => [
        {:method => "Cobrir a caixa d’água", :points => 450},
        {:method => "Vedar adequadamente com tapa e ou capa apropriada", :points => 200},
        {:method => "Outros recipientes: esfregue, seque, cubra ou sele.", :points => 350}
      ],

      :elimination_methods_in_es => [
        {:method => "Cubrir la caida del agua", :points => 450},
        {:method => "Tapar adecuadamente con tapa o con una capota apropiada", :points => 200},
        {:method => "Otros recipientes: limpie, seque, cubra o selle.", :points => 350}
      ]
    },

    {
      :breeding_site_in_pt => "Calha",
      :breeding_site_in_es => "Quebrada o charco",
      :elimination_methods_in_pt => [],
      :elimination_methods_in_es => []
    },

    {
      :breeding_site_in_pt => "Registros abertos",
      :breeding_site_in_es => "Registros abiertos",
      :elimination_methods_in_pt => [
        {:method => "Sele com cobertura impermeável para prevenir a penetração da água e ainda ter acesso ao registro.", :points => 300},
        {:method => "Preencha com areia ou terra e mude o acesso à válvula.", :points => 300},
        {:method => "Vedar.", :points => 300}
      ],
      :elimination_methods_in_es => [
        {:method => "Selle con una cubiert impermeable para prevenir la penetración de agua sin perder acceso al registro.", :points => 300},
        {:method => "Llene con arena o tierra y cambie de lugar el acceso a la válvula.", :points => 300},
        {:method => "Cancelación de registro.", :points => 300}
      ]
    },

    {
      :breeding_site_in_pt => "Laje e terraços com água",
      :breeding_site_in_es => "Loza y terrazas con agua",
      :elimination_methods_in_pt => [
        {:method => "Limpá-las.", :points => 300}
      ],

      :elimination_methods_in_es => [
        {:method => "Limpá-las.", :points => 300}
      ]
    },

    {
      :breeding_site_in_pt => "Piscinas",
      :breeding_site_in_es => "Piscinas",
      :elimination_methods_in_pt => [
        {:method => "Piscinas em uso: esfregue e limpe uma vez por semana", :points => 350},
        {:method => "Piscinas que não estão em uso: esfregue, seque e vire ao contrário. Em casos de piscina de plástico desmonte e guarde.", :points => 350}
      ],

      :elimination_methods_in_es => [
        {:method => "Piscinas em uso: esfregue e limpe uma vez por semana", :points => 350},
        {:method => "Piscinas que não estão em uso: esfregue, seque e vire ao contrário. Em casos de piscina de plástico desmonte e guarde.", :points => 350}
      ]
    },

    {
      :breeding_site_in_pt => "Poças d’água na rua",
      :breeding_site_in_es => "Pozas de agua en la calle",
      :elimination_methods_in_pt => [
        {:method => "Elimine a água com rodo ou vassoura", :points => 50}
      ],

      :elimination_methods_in_es => [
        {:method => "Elimine el agua con una escobilla de goma o una escoba", :points => 50}
      ]
    },

    {
      :breeding_site_in_pt => "Ralos",
      :breeding_site_in_es => "Drenajes",
      :elimination_methods_in_pt => [
        {:method => "Jogue água sanitária ou desinfetante semanalmente.", :points => 50},
        {:method => "Elimine entupimento", :points => 50},
        {:method => "Vede ralos não utilizados", :points => 50}
      ],

      :elimination_methods_in_es => [
        {:method => "Añada cloro o desinfectante semanalmente.", :points => 50},
        {:method => "Elimine la obstrucción", :points => 50},
        {:method => "Suspenda los drenajes no utilizados", :points => 50}
      ]
    },

    {
      :breeding_site_in_pt => "Plantas aquáticas em vaso de água",
      :breeding_site_in_es => "Plantas acuáticas en vasos de agua",
      :elimination_methods_in_pt => [
        {:method => "Retire a água acumulada nas folhas", :points => 50},
        {:method => "Regar semanalmente com água sanitária na proporção de uma colher de sopa para um litro de água.", :points => 50}
      ],

      :elimination_methods_in_es => [
        {:method => "Retire el agua acumulada en las hojas", :points => 50},
        {:method => "Regar semanalmente con agua clorada con una cucharada sopera por cada litro de agua.", :points => 50}
      ]
    }
  ]


  types_and_methods.each do |types_hash|
    # Find (or create) the breeding site.
    bs = BreedingSite.find_or_create_by_description_in_pt( types_hash[:breeding_site_in_pt] )
    bs.description_in_es = types_hash[:breeding_site_in_es]
    bs.save!

    # Find (or create) each method.
    types_hash[:elimination_methods_in_pt].each_with_index do |m, index|
      em                   = EliminationMethod.find_or_create_by_method( m[:method] )
      em.description_in_pt = m[:method]
      em.description_in_es = types_hash[:elimination_methods_in_es][index][:method]
      em.points            = m[:points]
      em.breeding_site_id  = bs.id
      em.save!
    end
  end



  puts "\n" * 3
  puts "[ok] Done seeding elimination types and methods"
  puts "-" * 80
end
