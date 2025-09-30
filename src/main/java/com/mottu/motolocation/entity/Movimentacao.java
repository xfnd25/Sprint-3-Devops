package com.mottu.motolocation.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "movimentacao") // Especifica o nome da tabela em minúsculas
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Movimentacao {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "moto_id", nullable = false) // Mapeia para a coluna 'moto_id'
    private Moto moto;

    @ManyToOne
    @JoinColumn(name = "sensor_id", nullable = false) // Mapeia para a coluna 'sensor_id'
    private Sensor sensor;

    @Column(name = "data_hora") // Mapeia para a coluna 'data_hora'
    private LocalDateTime dataHora;

    @PrePersist
    public void setTimestamp() {
        this.dataHora = LocalDateTime.now();
    }
}
