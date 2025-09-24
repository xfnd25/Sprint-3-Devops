package com.mottu.motolocation.controller;

import com.mottu.motolocation.dto.MotoDTO;
import com.mottu.motolocation.service.MotoService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/motos")
public class MotoController {

    private final MotoService motoService;

    public MotoController(MotoService motoService) {
        this.motoService = motoService;
    }

    @PostMapping
    public ResponseEntity<MotoDTO> createMoto(@Valid @RequestBody MotoDTO dto) {
        MotoDTO created = motoService.createMoto(dto);
        return new ResponseEntity<>(created, HttpStatus.CREATED);
    }

    @GetMapping("/{id}")
    public ResponseEntity<MotoDTO> getMotoById(@PathVariable Long id) {
        MotoDTO moto = motoService.getMotoById(id);
        return ResponseEntity.ok(moto);
    }

    @PutMapping("/{id}")
    public ResponseEntity<MotoDTO> updateMoto(@PathVariable Long id, @Valid @RequestBody MotoDTO dto) {
        MotoDTO updated = motoService.updateMoto(id, dto);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteMoto(@PathVariable Long id) {
        motoService.deleteMoto(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping
    public ResponseEntity<Page<MotoDTO>> listMotos(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "placa") String sortBy,
            @RequestParam(required = false) String placaFiltro) {

        Page<MotoDTO> result = motoService.listMotos(page, size, sortBy, placaFiltro);
        return ResponseEntity.ok(result);
    }

}
