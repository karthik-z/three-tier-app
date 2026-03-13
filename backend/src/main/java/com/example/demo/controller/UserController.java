package com.example.demo.controller;

import com.example.demo.model.User;
import com.example.demo.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {

    private final UserRepository repo;

    public UserController(UserRepository repo) {
        this.repo = repo;
    }

    @GetMapping
    public List<User> getAll() {
        return repo.findAll();
    }

    @PostMapping
    public User create(@RequestBody User user) {
        return repo.save(user);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        repo.deleteById(id);
        return ResponseEntity.ok(Map.of("message", "User deleted"));
    }

    // Health-check shortcut
    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "UP", "service", "backend");
    }
}
