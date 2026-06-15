package com.expenzo.api.controller;

import com.expenzo.api.dto.AuthResponse;
import com.expenzo.api.dto.LoginRequest;
import com.expenzo.api.dto.RegisterRequest;
import com.expenzo.api.model.User;
import com.expenzo.api.service.UserService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private UserService userService;

    @Autowired
    private com.expenzo.api.config.JwtUtil jwtUtil;

    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest request) {
        try {
            User user = userService.register(request.getEmail(), request.getPassword(), request.getName());
            String token = userService.login(request.getEmail(), request.getPassword());
            return ResponseEntity.ok(new AuthResponse(token, user.getEmail(), user.getName()));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(java.util.Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request) {
        try {
            String token = userService.login(request.getEmail(), request.getPassword());
            User user = userService.findById(Long.parseLong(jwtUtil.getUserIdFromToken(token)));
            return ResponseEntity.ok(new AuthResponse(token, user.getEmail(), user.getName()));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(java.util.Map.of("error", e.getMessage()));
        }
    }
}
