package com.javatechie.crud.example.repository;

import com.javatechie.crud.example.entity.Product;
import org.springframework.data.jpa.repository.JpaRepository;
// For ProductRepository.java
import java.util.List;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

// For ProductController.java
import org.springframework.http.ResponseEntity;

public interface ProductRepository extends JpaRepository<Product,Integer> {
    Product findByName(String name);
    List<Product> findByNameContainingIgnoreCase(String keyword);
    @Query("SELECT p FROM Product p WHERE " +
       "(:name IS NULL OR LOWER(p.name) LIKE LOWER(CONCAT('%', :name, '%'))) AND " +
       "(:minPrice IS NULL OR p.price >= :minPrice) AND " +
       "(:maxPrice IS NULL OR p.price <= :maxPrice)")
    List<Product> searchProducts(@Param("name") String name,
                             @Param("minPrice") Double minPrice,
                             @Param("maxPrice") Double maxPrice);
}

