package com.mottu.motolocation.controller;

import com.mottu.motolocation.dto.MovimentacaoDTO;
import com.mottu.motolocation.service.MovimentacaoService;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/movimentacoes")
public class MovimentacaoController {

    private final MovimentacaoService movimentacaoService;

    public MovimentacaoController(MovimentacaoService movimentacaoService) {
        this.movimentacaoService = movimentacaoService;
    }

    public static class MovimentacaoRequest {
        @NotBlank
        private String rfid;

        @NotBlank
        private String sensorCodigo;

        public String getRfid() {
            return rfid;
        }

        public void setRfid(String rfid) {
            this.rfid = rfid;
        }

        public String getSensorCodigo() {
            return sensorCodigo;
        }

        public void setSensorCodigo(String sensorCodigo) {
            this.sensorCodigo = sensorCodigo;
        }
    }

    @PostMapping
    public ResponseEntity<MovimentacaoDTO> registrarMovimentacao(@Valid @RequestBody MovimentacaoRequest request) {
        MovimentacaoDTO movDTO = movimentacaoService.registrarMovimentacao(request.getRfid(), request.getSensorCodigo());
        return new ResponseEntity<>(movDTO, HttpStatus.CREATED);
    }

    @GetMapping("/moto/{motoId}")
    public ResponseEntity<Page<MovimentacaoDTO>> listarMovimentacoesPorMoto(
            @PathVariable Long motoId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "dataHora") String sortBy) {

        Page<MovimentacaoDTO> result = movimentacaoService.listarMovimentacoesPorMoto(motoId, page, size, sortBy);
        return ResponseEntity.ok(result);
    }
}
