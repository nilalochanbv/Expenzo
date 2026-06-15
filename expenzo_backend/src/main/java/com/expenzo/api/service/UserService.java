package com.expenzo.api.service;

import com.expenzo.api.config.JwtUtil;
import com.expenzo.api.config.PasswordUtil;
import com.expenzo.api.model.User;
import com.expenzo.api.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtUtil jwtUtil;

    public User register(String email, String password, String name) {
        if (userRepository.findByEmail(email).isPresent()) {
            throw new RuntimeException("Email already in use");
        }

        User user = User.builder()
                .email(email)
                .password(PasswordUtil.hash(password))
                .name(name)
                .build();

        return userRepository.save(user);
    }

    public String login(String email, String password) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Invalid email or password"));

        if (!PasswordUtil.verify(password, user.getPassword())) {
            throw new RuntimeException("Invalid email or password");
        }

        return jwtUtil.generateToken(user.getId(), user.getEmail());
    }

    public User findById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }
}
