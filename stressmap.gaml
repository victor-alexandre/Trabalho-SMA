/***
* Name: stressmap
* Author: Florentino, Victor Alexandre, Vinicius Borges Alencar
* Description: Projeto de Mapa de Stress para disciplina de Sistemas Multiagentes, INF, UFG - 2019/1
* Tags: stress, map, class, classroom, teacher, students
***/
 
model stressmap
 
/* Definição de modelo para o projeto */
global {
 
    int countDangerousStudents <- 0;
   
    //aluno escolhido para ser monitorado
    student singular_one;
   
    //Perfil do professor poderá ser rígido ou relaxado, se for rídigo o range das msg são menores.
    string teacher_profile;
    // Essa influência mudará o range das msgs e quantidade de msgs transmitidas.
    float teacher_influence <- 1.0;
   
    // Dados da grid
    int grid_height <- 10;
    int grid_width <- 9;
   
    //Número total de estudantes na classe
    int nb_students <- 40;
 
    bool sleeping <- false;
    //Lista de períodos
    list<string> period_list <- ['Entrada','Aula 1','Recreio','Aula 2', 'Saída','Prova', 'Dormindo'];
    string periodo_atual;
    //Número que indica o período atual
    int periodo;
    //Número que indica o dia
    int day;
    //String para indicar o dia atual
    string dia_atual;
   
    //Indica se está ocorrendo prova ou não
    bool ocurring_exams;
    //Probabilidade de ocorrer prova
    float exams_probability <- 0.20;
   
    //variável que informa o range das mensagens, ela será alterada de acordo com o período de aula.
    float particular_message_range <- 15.0;
    float area_message_range <- 10.0;
   
/*     //stressors factors
    float exams_stress <- 0.49;
    float career_stress <- 0.1283;
    float family_stress <- 0.0954;
    float economic_stress <- 0.1186;
    float homework_stress <- 0.0329;
    float teacher_stress <- 0.0296;
    float relationships_stress <- 0.0493;
*/
 
    float exams_stress <- 0.5;
    float career_stress <- 0.5;
    float family_stress <- 0.5;
    float economic_stress <- 0.5;
    float homework_stress <- 0.5;
    float teacher_stress <- 0.5;
    float relationships_stress <- 0.5;
 
 
     //Número de estudantes bulinadores
    int nb_bully <- 35;
    //Número de estudantes amigáveis
    int nb_friendly <- 2;
    //Número de estudantes amigaveis
    int nb_neutro <- nb_students - nb_bully - nb_friendly;
                             
    init {
        //Inicialização de algumas variáveis
        dia_atual <- "Dia 0";
        day <- 0;
        periodo <- -1;
        ocurring_exams <- false;
 
       
        loop i from: 0 to: grid_height - 1 {
            loop j from: 0 to: grid_width - 1 {
                if(i > 1 and (j mod 2 = 0)) {
                    seats grid_seat <- seats grid_at {j, i};                                                                                                                                           
                    int tmp;                    
                    if(nb_bully > 0 and nb_neutro > 0 and nb_friendly > 0){
                        tmp <- rnd_choice([1, 2, 3]);
                        if(tmp = 1 and nb_bully > 0) {
                            create bully with:(location: grid_seat.location);
                            nb_bully <- nb_bully - 1;
                         } else if(tmp = 2 and nb_friendly > 0) {
                            create friendly with:(location: grid_seat.location);
                            nb_friendly <- nb_friendly - 1;
                         } else{
                            create student with:(location: grid_seat.location);
                         }  
                    } else if (nb_bully > 0){
                        create bully with:(location: grid_seat.location);
                        nb_bully <- nb_bully - 1;                      
                    } else if (nb_friendly > 0){
                        create friendly with:(location: grid_seat.location);
                        nb_friendly <- nb_friendly - 1;                
                    } else {
                        create student with:(location: grid_seat.location);
                    }
                   
                } else if(i = 0 and j = 4) {
                    seats grid_seat <- seats grid_at {j, i};
                    create teacher with:(location: grid_seat.location);
                }
            }
        }        
       //Vou atribuir um estudante aleatório para ser o monitorado
        singular_one <- one_of(student + bully + friendly);            
    }
 
    //Soma dos estresses de todos os alunos
    float sum_stress <- 0.0;
    //Pico máximo atingido pela soma dos estresses.
    float max_stress <- 0.0;
 
 
    reflex max_stress_update {
        sum_stress <- student sum_of(each.stress) + bully sum_of(each.stress) + friendly sum_of(each.stress);
       
        if (sum_stress > max_stress){
            max_stress<- sum_stress;
        }
    }
       
    //A cada 100 cyclos o dia muda
    reflex change_day when: every(120#cycles) {
        day <- day + 1;
        dia_atual <- "Dia " + day;  
    }
   
    //A cada 20 cyclos o período muda
    reflex change_period when: every(20#cycles) {
        periodo <- (periodo + 1) mod 6;
        ocurring_exams <- false;            
        //Se for durante a Aula 1 ou 2 há uma probabilidade de ocorrer prova
        if(periodo = 1 or periodo = 3){
            ocurring_exams <- flip(exams_probability) ? true : false;
            if(ocurring_exams){
                //Período atual recebe o valor de Prova
                periodo_atual <- "Prova";
            }
            else{
                periodo_atual <- period_list[periodo];
                //Durante a aula o range das mensagens são limitados
                //Sorteia um perfil para o prof atual. 0 == Rígido, 1 == Neutro, 2 == Relaxado
                int sorteia_prof <- rnd_choice([0, 1, 2]);
                //O random acima sorteia uma posição da lista
                if(sorteia_prof = 0){
                    teacher_influence <- 0.75;
                    teacher_profile <- 'Rígido';
                }else if (sorteia_prof = 1){
                    teacher_profile <- 'Neutro';
                    teacher_influence <- 1.0;
                }else{
                    teacher_profile <- 'Relaxado';
                    teacher_influence <- 1.25;
                }
               
                // o range das msgs são alterados de acordo com o perfil do prof
                particular_message_range <- 8.0*teacher_influence;
                area_message_range <- 4.0*teacher_influence;
                sleeping <- false;
            }
        }
        else if(periodo = 0 or periodo = 2 or periodo = 4){
            periodo_atual <- period_list[periodo];
            //Durante o entrada, recreio e saída o range das mensagens são maiores e não há professores
            particular_message_range <- 15.0;
            area_message_range <- 10.0;
 
            teacher_profile <- '------';
            teacher_influence <- 1.0;
            sleeping <- false;
        }
        else{
            periodo_atual <- "Dormindo";
            sleeping <- true;
            teacher_profile <- '------';
        }        
                   
    }
}
 
grid seats width: grid_width height: grid_height {
   
}
 
species student {
    //Estresse que sempre estará presente
    float stresses_family <- flip(family_stress) ? 1.0 : 0.0;
    float stresses_economic <- flip(economic_stress) ? 1.0 : 0.0;
    float stresses_carrer <- flip(career_stress) ? 1.0 : 0.0;
    float stresses_homework <- flip(homework_stress) ? 1.0 : 0.0;    
    float basic_stressors <- stresses_family + stresses_economic + stresses_carrer + stresses_homework;
 
 
    //Estresse que etará presente no momento das comunicações
    float stresses_relationship <- flip(relationships_stress) ? 1.5 : 1.0;
   
    //Estresse que estará presente de acordo com o ambiente
    bool stresses_exam <- flip(exams_stress) ? true : false;
    float stresses_teacher <- flip(teacher_stress) ? 1.0 : 0.0;
    float ambient_stressors <- 0.0;
   
 
 
    //Social é a mensagem recebida a partir da comunicação com outros estudantes  
    float msg <- 1.0;
    float stress <- 0.0;
   
    //Propensão para estressar, vai variar de acordo com o estresse atual
    float tend_to_stress <-  1.0;
   
    //Fator de dominancia, ele influenciará no range da mensagem que um aluno envia.  
    float dominance <- rnd(2.0,7.0);  
    //Fator que influencia na quantidade de mensagens enviadas por um aluno.
    float communicative <- rnd(1.0);
   
    //Estudantes em que este agente comunicará
    //Comunicação direta para outro estudante
    student partner;
    //Comunicação em área
    list<agent> neighborhood;
   
    //Indica se o aluno está se comunicando ou não. Serve para nos auxiliar a desenhar uma linha entre o emissor e o receptor.  
    bool communicating <- false;
 
    reflex atualization {      
        //Atualização da tendencia de estressar para manter limitado. Observe que caso o valor seja entre 0-1 então o tend_to_stress reduzirá o stress
        if(tend_to_stress > 3.0){
            tend_to_stress <- 3.0;
        }else if(tend_to_stress < 0){
            tend_to_stress <- 0.0;
        }
       
        if(stress < 0){
            stress <- 0.0;
        }
       
        if(stress > 40){
            countDangerousStudents <- countDangerousStudents + 1;
            write self.name;
        }      
    }
   
    reflex exams when: ocurring_exams{
        if(stresses_exam){
            ambient_stressors<- 2.0 + stresses_teacher;
        }
        else{
            ambient_stressors<- stresses_teacher;
        }
    }
   
    reflex stress_equation {
        //O valor máximo do stress é de 47.5 para um estudante, pois (4 + 3)*(1.5*1.5)*3 = 47.5
        float stress_calc <- ((basic_stressors + ambient_stressors) * (stresses_relationship * msg))*tend_to_stress;
        stress <- stress_calc;
        msg <- 1.0;
        if(!sleeping){
            tend_to_stress <-  tend_to_stress + stress*(20/100);
        }
    }
   
    reflex relax_slowly_with_time {
        stress <- stress >  0 ? (stress - stress*(5/100)): 0;
    }
   
    reflex relax_after_new_day when: sleeping {
        tend_to_stress <- tend_to_stress - tend_to_stress*(32/100);        
    }
       
    aspect base {
        // muda a cor dependendo do nível de stress
        if(stress < 10){
            draw circle(2.5) color: #green;
        } else if(stress < 20){
            draw circle(2.5) color: #blue;
        } else if(stress < 30){
            draw circle(2.5) color: #yellow;
        } else if(stress < 40){
            draw circle(2.5) color: #red;
        } else{
            draw circle(2.5) color: #black;
        }
       
        draw string(stress with_precision 4) color: #black;
        if(communicating) {
            draw polyline([self.location, partner.location]) color: #black end_arrow: 2.0;
            communicating <- false;
        }
    }          
}
 
species bully parent: student {
    //Posso colocar dominancia fixa para esse perfil de aluno
    //float dominance <- 7.0;
    //float communicative <- 0.1;
   
    reflex send_particular_message when: flip(communicative) and !ocurring_exams and !sleeping{
        communicating <- true;
        float message_to_send <- flip(0.8) ? 1.5 : 1;  
        student partner_tmp <- one_of(student at_distance(dominance*particular_message_range) + bully at_distance(dominance*particular_message_range)+ friendly at_distance(dominance*particular_message_range));
        partner <- partner_tmp;
        partner.msg <- message_to_send;
        partner.tend_to_stress <- partner.tend_to_stress + partner.tend_to_stress*(10/100);
        self.stress <- self.stress - msg*partner.tend_to_stress;
    }
   
    reflex send_area_message when: flip(communicative) and !ocurring_exams and !sleeping{
        communicating <- true;
        float message_to_send <- flip(0.8) ? 1.5 : 1;
        list<student> neighbors <- student at_distance(dominance*area_message_range) + bully at_distance(dominance*area_message_range)+ friendly at_distance(dominance*area_message_range);
        ask neighbors {
            self.msg <- message_to_send;
            self.tend_to_stress <- self.tend_to_stress + self.tend_to_stress*(4/100);
            myself.neighborhood <- neighbors;
        }
    }    
   
   
    aspect base {
        // muda a cor dependendo do nível de stress
        if(stress < 10){
            draw triangle(7.0) color: #green;
        } else if(stress < 20){
            draw triangle(7.0) color: #blue;
        } else if(stress < 30){
            draw triangle(7.0) color: #yellow;
        } else if(stress < 40){
            draw triangle(7.0) color: #red;
        } else{
            draw triangle(7.0) color: #black;
        }
       
        draw string(stress with_precision 4) color: #black;
        if(communicating) {
            communicating <- false;
            draw polyline([self.location, partner.location]) color: #red end_arrow: 2.0;
            //Para ele não guardar o parceiro na variável após desenhar na tela
            partner <- self;                        
            if(length(self.neighborhood) > 0){
                loop aibou over: self.neighborhood {
                    draw polyline([self.location, aibou.location]) color: #red end_arrow: 2.0;
                }
                self.neighborhood <- [];
            }
        }
    }
   
}
 
species friendly parent: student {
    //Posso colocar dominancia fixa para esse perfil de aluno
    //float dominance <- 5.0;
    //float communicative <- 0.5;
   
    reflex send_particular_message when: flip(communicative) and !ocurring_exams and !sleeping{
        communicating <- true;
        float message_to_send <- flip(0.8) ? 0.75 : 1;
        student partner_tmp <- one_of(student at_distance(dominance*particular_message_range) + bully at_distance(dominance*particular_message_range)+ friendly at_distance(dominance*particular_message_range));
        partner <- partner_tmp;
        partner.msg <- message_to_send;
        partner.tend_to_stress <- partner.tend_to_stress - partner.tend_to_stress*(10/100);
        self.stress <- self.stress - msg*partner.tend_to_stress;
    }
   
    reflex send_area_message when: flip(communicative) and !ocurring_exams and !sleeping {
        communicating <- true;
        float message_to_send <- flip(0.8) ? 0.75 : 1;
        list<student> neighbors <- student at_distance(dominance*area_message_range) + bully at_distance(dominance*area_message_range)+ friendly at_distance(dominance*area_message_range);
        ask neighbors {
            self.msg <- message_to_send;
            self.tend_to_stress <- self.tend_to_stress - self.tend_to_stress*(4/100);
            myself.neighborhood <- neighbors;
        }
    }
   
 
    aspect base {
        // muda a cor dependendo do nível de stress
        if(stress < 10){
            draw square(4.5) color: #green;
        } else if(stress < 20){
            draw square(4.5) color: #blue;
        } else if(stress < 30){
            draw square(4.5) color: #yellow;
        } else if(stress < 40){
            draw square(4.5) color: #red;
        } else{
            draw square(4.5) color: #black;
        }
       
        draw string(stress with_precision 4) color: #black;
        if(communicating) {
            communicating <- false;
            draw polyline([self.location, partner.location]) color: #green end_arrow: 2.0;
            //Para ele não guardar o parceiro na variável após desenhar na tela
            partner <- self;            
            if(length(self.neighborhood) > 0){
                loop aibou over: self.neighborhood {
                    draw polyline([self.location, aibou.location]) color: #green end_arrow: 2.0;
                }
                self.neighborhood <- [];
            }
        }
    }
   
}
 
species teacher {
    aspect base {
        draw triangle(6.0) color: #red ;
        draw "T" at: location + {-1.5, 1.5, 0} color: #black font: font("SansSerif",28,#italic) perspective: false ;
    }
}
 
experiment lesson type: gui {
    output {
        display classroom {
            grid seats lines: #black;
            species student aspect: base;
            species teacher aspect: base;
            species bully aspect: base;
            species friendly aspect: base;
        }
       
        monitor "Soma do stress geral" value: sum_stress;
        monitor "Estresse geral máximo atingido" value: max_stress;
        monitor "Tempo" value: dia_atual;
        monitor "Período" value: periodo_atual;
        monitor "Perfil do Professor" value: teacher_profile;
        monitor "Estudantes Perigosos" value: countDangerousStudents;
       
       
        display my_overall_chart {
            chart "Stress Overall Variation"{              
                data "Overall stress" value: student sum_of(each.stress) + bully sum_of(each.stress) + friendly sum_of(each.stress);
            }
        }
       
        display my_singular_chart {            
            chart "Stress Student Variation"{
                list<student> classe <- student + bully + friendly;
                data "Selected student stress" value: one_of(agents of_species student + agents of_species bully+ agents of_species friendly).stress;
                //data "Selected student stress" value: one_of(classe).stress;
               //string text <- "Selected" +  singular_one.name + "stress";                          
               //data "Selected student stress" value: singular_one.stress;
            }
        }              
    }  
}