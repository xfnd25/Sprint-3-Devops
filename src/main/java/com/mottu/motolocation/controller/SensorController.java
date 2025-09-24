package com.mottu.motolocation.controller;

import com.mottu.motolocation.dto.SensorDTO;
import com.mottu.motolocation.service.SensorService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/sensores")
public class SensorController {

    private final SensorService sensorService;

    public SensorController(SensorService sensorService) {
        this.sensorService = sensorService;
    }

    @PostMapping
    public ResponseEntity<SensorDTO> createSensor(@Valid @RequestBody SensorDTO dto) {
        SensorDTO created = sensorService.createSensor(dto);
        return new ResponseEntity<>(created, HttpStatus.CREATED);
    }

    @GetMapping("/{id}")
    public ResponseEntity<SensorDTO> getSensorById(@PathVariable Long id) {
        SensorDTO sensor = sensorService.getSensorById(id);
        return ResponseEntity.ok(sensor);
    }

    @PutMapping("/{id}")
    public ResponseEntity<SensorDTO> updateSensor(@PathVariable Long id, @Valid @RequestBody SensorDTO dto) {
        SensorDTO updated = sensorService.updateSensor(id, dto);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteSensor(@PathVariable Long id) {
        sensorService.deleteSensor(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping
    public ResponseEntity<Page<SensorDTO>> listSensors(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "codigo") String sortBy,
            @RequestParam(required = false) String codigoFiltro) {

        Page<SensorDTO> result = sensorService.listSensors(page, size, sortBy, codigoFiltro);
        return ResponseEntity.ok(result);
    }
}
